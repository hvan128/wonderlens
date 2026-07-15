#!/usr/bin/env ruby
# frozen_string_literal: true

# Create WonderLens Plus subscriptions through official store APIs.
#
# Required env for Apple:
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_FILEPATH or ASC_KEY_CONTENT
#
# Required env for Google Play:
#   SUPPLY_JSON_KEY
#
# Optional env:
#   WONDERLENS_PLUS_YEARLY_ID, WONDERLENS_PLUS_MONTHLY_ID
#   WL_PLUS_YEARLY_VND, WL_PLUS_MONTHLY_VND
#   WL_PLUS_APPLE_TERRITORY=VNM
#   WL_PLUS_REVIEW_SCREENSHOT=/path/to/review.png

require "json"
require "net/http"
require "uri"
require "digest"
require "spaceship"
require "google/apis/androidpublisher_v3"
require "googleauth"

$stdout.sync = true

CONFIG = {
  ios_bundle_id: ENV.fetch("IOS_BUNDLE_ID", "com.wonderlens.wonderlens"),
  android_package: ENV.fetch("ANDROID_PACKAGE_NAME", "com.wonderlens.wonderlens"),
  group_reference_name: ENV.fetch("WL_PLUS_GROUP_NAME", "WonderLens Plus"),
  yearly_id: ENV.fetch("WONDERLENS_PLUS_YEARLY_ID", "wonderlens_plus_yearly"),
  monthly_id: ENV.fetch("WONDERLENS_PLUS_MONTHLY_ID", "wonderlens_plus_monthly"),
  yearly_price_vnd: ENV.fetch("WL_PLUS_YEARLY_VND", "499000"),
  monthly_price_vnd: ENV.fetch("WL_PLUS_MONTHLY_VND", "89000"),
  google_regions_version: ENV.fetch("GOOGLE_PLAY_REGIONS_VERSION", "2022/02"),
  apple_territory: ENV.fetch("WL_PLUS_APPLE_TERRITORY", "VNM"),
  review_screenshot: ENV["WL_PLUS_REVIEW_SCREENSHOT"]
}.freeze

PRODUCTS = [
  {
    key: :yearly,
    product_id: CONFIG[:yearly_id],
    base_plan_id: "yearly",
    period: "P1Y",
    apple_period: "ONE_YEAR",
    title_vi: "WonderLens Plus Năm",
    title_en: "WonderLens Plus Yearly",
    description_vi: "Mở WonderLens Plus trong một năm, có dùng thử 3 ngày.",
    description_en: "Unlock WonderLens Plus for one year with a 3-day trial.",
    price_vnd: CONFIG[:yearly_price_vnd],
    trial_days: 3
  },
  {
    key: :monthly,
    product_id: CONFIG[:monthly_id],
    base_plan_id: "monthly",
    period: "P1M",
    apple_period: "ONE_MONTH",
    title_vi: "WonderLens Plus Tháng",
    title_en: "WonderLens Plus Monthly",
    description_vi: "Mở WonderLens Plus theo từng tháng.",
    description_en: "Unlock WonderLens Plus month by month.",
    price_vnd: CONFIG[:monthly_price_vnd],
    trial_days: 0
  }
].freeze

def log(message)
  puts "• #{message}"
end

def warn_step(message)
  warn "⚠ #{message}"
end

def api_error_message(error)
  body = error.respond_to?(:body) ? error.body : nil
  return error.message if body.nil? || body.empty?

  parsed = JSON.parse(body)
  details = parsed.dig("error", "details") || parsed["errors"]
  [error.message, parsed.dig("error", "message"), details].compact.join(" | ")
rescue JSON::ParserError
  [error.message, body].compact.join(" | ")
end

class AppStoreConnectClient
  API_ROOT = "https://api.appstoreconnect.apple.com"

  def initialize
    key_id = ENV.fetch("ASC_KEY_ID")
    issuer_id = ENV.fetch("ASC_ISSUER_ID")
    key_path = ENV["ASC_KEY_FILEPATH"]
    key_content = ENV["ASC_KEY_CONTENT"]

    token =
      if key_content && !key_content.empty?
        Spaceship::ConnectAPI::Token.create(
          key_id: key_id,
          issuer_id: issuer_id,
          key: key_content,
          is_key_content_base64: true
        )
      else
        Spaceship::ConnectAPI::Token.create(
          key_id: key_id,
          issuer_id: issuer_id,
          filepath: File.expand_path(key_path)
        )
      end

    @jwt = token.text
  end

  def get(path, query = {})
    request(:get, path, query: query)
  end

  def post(path, body)
    request(:post, path, body: body)
  end

  def patch(path, body)
    request(:patch, path, body: body)
  end

  def delete(path)
    request(:delete, path)
  end

  private

  def request(method, path, query: {}, body: nil)
    uri = URI("#{API_ROOT}/#{path.sub(%r{^/}, "")}")
    uri.query = URI.encode_www_form(query) unless query.empty?

    req =
      case method
      when :get then Net::HTTP::Get.new(uri)
      when :post then Net::HTTP::Post.new(uri)
      when :patch then Net::HTTP::Patch.new(uri)
      when :delete then Net::HTTP::Delete.new(uri)
      else raise ArgumentError, "Unsupported ASC method #{method}"
      end
    req["Authorization"] = "Bearer #{@jwt}"
    req["Content-Type"] = "application/json"
    req.body = JSON.generate(body) if body

    res = nil
    3.times do |attempt|
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      break unless res.is_a?(Net::HTTPServerError) && attempt < 2

      sleep(1 + attempt)
    end
    parsed = res.body.nil? || res.body.empty? ? {} : JSON.parse(res.body)
    return parsed if res.is_a?(Net::HTTPSuccess)

    message = parsed["errors"]&.map { |e| "#{e["code"]}: #{e["detail"]}" }&.join(" | ")
    raise "ASC #{method.upcase} #{path} failed (#{res.code}): #{message || res.body}"
  end
end

def create_apple_subscriptions
  log("Apple: tìm app #{CONFIG[:ios_bundle_id]}")
  client = AppStoreConnectClient.new
  apps = client.get("v1/apps", { "filter[bundleId]" => CONFIG[:ios_bundle_id] })
  app = apps.fetch("data").first
  raise "Không tìm thấy app iOS #{CONFIG[:ios_bundle_id]} trên App Store Connect" unless app

  app_id = app.fetch("id")
  group = find_or_create_apple_group(client, app_id)
  ensure_apple_group_localizations(client, group.fetch("id"))
  PRODUCTS.each do |product|
    subscription = find_apple_subscription(client, group.fetch("id"), product[:product_id])
    if subscription
      log("Apple: subscription #{product[:product_id]} đã tồn tại")
    else
      subscription = create_apple_subscription(client, group.fetch("id"), product)
      log("Apple: đã tạo subscription #{product[:product_id]}")
    end
    subscription_id = subscription.fetch("id")
    ensure_apple_localizations(client, subscription_id, product)
    ensure_apple_availability(client, subscription_id)
    ensure_apple_price(client, subscription_id, product)
    ensure_apple_plan_availability(client, subscription_id)
    ensure_apple_intro_offer(client, subscription_id, product)
    ensure_apple_review_screenshot(client, subscription_id, product)
  end
rescue KeyError => e
  warn_step("Apple: thiếu env #{e.key}. Bỏ qua iOS.")
rescue => e
  warn_step("Apple: #{e.message}")
end

def find_or_create_apple_group(client, app_id)
  groups = apple_get_first_working(client, [
    ["v1/apps/#{app_id}/subscriptionGroups", { "limit" => 200 }],
    ["v1/subscriptionGroups", { "filter[app]" => app_id, "limit" => 200 }]
  ])
  group = groups.fetch("data", []).find do |g|
    g.dig("attributes", "referenceName") == CONFIG[:group_reference_name]
  end
  return group if group

  payload = {
    data: {
      type: "subscriptionGroups",
      attributes: { referenceName: CONFIG[:group_reference_name] },
      relationships: {
        app: { data: { type: "apps", id: app_id } }
      }
    }
  }
  client.post("v1/subscriptionGroups", payload).fetch("data")
end

def ensure_apple_group_localizations(client, group_id)
  existing = client.get(
    "v1/subscriptionGroups/#{group_id}/subscriptionGroupLocalizations",
    { "limit" => 200 }
  )
  locales = existing.fetch("data", []).map { |loc| loc.dig("attributes", "locale") }.compact
  [
    ["vi", "WonderLens Plus", "WonderLens"],
    ["en-US", "WonderLens Plus", "WonderLens"]
  ].each do |locale, name, app_name|
    next if locales.include?(locale)

    payload = {
      data: {
        type: "subscriptionGroupLocalizations",
        attributes: { locale: locale, name: name, customAppName: app_name },
        relationships: {
          subscriptionGroup: { data: { type: "subscriptionGroups", id: group_id } }
        }
      }
    }
    client.post("v1/subscriptionGroupLocalizations", payload)
    log("Apple: group localization #{locale} ✓")
  rescue => e
    warn_step("Apple group localization #{locale}: #{api_error_message(e)}")
  end
end

def find_apple_subscription(client, group_id, product_id)
  response = apple_get_first_working(client, [
    ["v1/subscriptionGroups/#{group_id}/subscriptions", { "limit" => 200 }],
    ["v1/subscriptions", { "filter[subscriptionGroup]" => group_id, "limit" => 200 }]
  ])
  response.fetch("data", []).find do |sub|
    sub.dig("attributes", "productId") == product_id
  end
end

def create_apple_subscription(client, group_id, product)
  attributes = {
    name: product[:title_en],
    productId: product[:product_id],
    familySharable: false,
    reviewNote: "WonderLens Plus subscription for parent-approved STEM discovery.",
    subscriptionPeriod: product[:apple_period]
  }
  payload = {
    data: {
      type: "subscriptions",
      attributes: attributes,
      relationships: {
        group: { data: { type: "subscriptionGroups", id: group_id } }
      }
    }
  }
  client.post("v1/subscriptions", payload).fetch("data")
rescue => e
  raise unless e.message.include?("subscriptionPeriod") || e.message.include?("ATTRIBUTE")

  payload[:data][:attributes].delete(:subscriptionPeriod)
  client.post("v1/subscriptions", payload).fetch("data")
end

def ensure_apple_localizations(client, subscription_id, product)
  existing = apple_get_first_working(client, [
    ["v1/subscriptions/#{subscription_id}/subscriptionLocalizations", { "limit" => 200 }],
    ["v1/subscriptionLocalizations", { "filter[subscription]" => subscription_id, "limit" => 200 }]
  ])
  locales = existing.fetch("data", []).map { |loc| loc.dig("attributes", "locale") }.compact
  [
    ["vi", product[:title_vi], product[:description_vi]],
    ["en-US", product[:title_en], product[:description_en]]
  ].each do |locale, name, description|
    next if locales.include?(locale)

    payload = {
      data: {
        type: "subscriptionLocalizations",
        attributes: { locale: locale, name: name, description: description },
        relationships: {
          subscription: { data: { type: "subscriptions", id: subscription_id } }
        }
      }
    }
    client.post("v1/subscriptionLocalizations", payload)
    log("Apple: localization #{product[:product_id]} #{locale} ✓")
  rescue => e
    warn_step("Apple localization #{product[:product_id]} #{locale}: #{e.message}")
  end
end

def ensure_apple_availability(client, subscription_id)
  existing = client.get("v1/subscriptions/#{subscription_id}/subscriptionAvailability")
  return if existing["data"]
rescue => e
  raise unless e.message.include?("NOT_FOUND")

  payload = {
    data: {
      type: "subscriptionAvailabilities",
      attributes: { availableInNewTerritories: false },
      relationships: {
        availableTerritories: {
          data: [{ type: "territories", id: CONFIG[:apple_territory] }]
        },
        subscription: { data: { type: "subscriptions", id: subscription_id } }
      }
    }
  }
  client.post("v1/subscriptionAvailabilities", payload)
  log("Apple: availability #{CONFIG[:apple_territory]} ✓")
rescue => e
  warn_step("Apple availability #{subscription_id}: #{api_error_message(e)}")
end

def ensure_apple_plan_availability(client, subscription_id)
  existing = client.get(
    "v1/subscriptions/#{subscription_id}/planAvailabilities",
    { "limit" => 20 }
  )
  return if existing.fetch("data", []).any? do |availability|
    availability.dig("attributes", "planType") == "UPFRONT"
  end

  payload = {
    data: {
      type: "subscriptionPlanAvailabilities",
      attributes: { availableInNewTerritories: false, planType: "UPFRONT" },
      relationships: {
        availableTerritories: {
          data: [{ type: "territories", id: CONFIG[:apple_territory] }]
        },
        subscription: { data: { type: "subscriptions", id: subscription_id } }
      }
    }
  }
  client.post("v1/subscriptionPlanAvailabilities", payload)
  log("Apple: plan availability UPFRONT #{CONFIG[:apple_territory]} ✓")
rescue => e
  warn_step("Apple plan availability #{subscription_id}: #{api_error_message(e)}")
end

def ensure_apple_price(client, subscription_id, product)
  existing = client.get("v1/subscriptions/#{subscription_id}/prices", { "limit" => 20 })
  return if existing.fetch("data", []).any?

  price_point = find_apple_price_point(client, subscription_id, product[:price_vnd])
  unless price_point
    warn_step("Apple price #{product[:product_id]}: không tìm thấy price point #{product[:price_vnd]} VND")
    return
  end

  payload = {
    data: {
      type: "subscriptionPrices",
      relationships: {
        subscription: { data: { type: "subscriptions", id: subscription_id } },
        territory: { data: { type: "territories", id: CONFIG[:apple_territory] } },
        subscriptionPricePoint: {
          data: { type: "subscriptionPricePoints", id: price_point.fetch("id") }
        }
      }
    }
  }
  client.post("v1/subscriptionPrices", payload)
  log("Apple: price #{product[:price_vnd]} VND ✓")
rescue => e
  warn_step("Apple price #{product[:product_id]}: #{api_error_message(e)}")
end

def find_apple_price_point(client, subscription_id, price_vnd)
  cursor = nil
  loop do
    query = { "filter[territory]" => CONFIG[:apple_territory], "limit" => 200 }
    query["cursor"] = cursor if cursor
    response = client.get("v1/subscriptions/#{subscription_id}/pricePoints", query)
    found = response.fetch("data", []).find do |point|
      point.dig("attributes", "customerPrice").to_s == price_vnd.to_s
    end
    return found if found

    cursor = response.dig("meta", "paging", "nextCursor")
    return nil unless cursor
  end
end

def ensure_apple_intro_offer(client, subscription_id, product)
  return unless product[:trial_days].positive?

  existing = client.get("v1/subscriptions/#{subscription_id}/introductoryOffers", { "limit" => 20 })
  return if existing.fetch("data", []).any?

  duration = apple_trial_duration(product[:trial_days])
  unless duration
    warn_step("Apple intro offer #{product[:product_id]}: unsupported trial #{product[:trial_days]} days")
    return
  end

  payload = {
    data: {
      type: "subscriptionIntroductoryOffers",
      attributes: {
        duration: duration,
        numberOfPeriods: 1,
        offerMode: "FREE_TRIAL"
      },
      relationships: {
        subscription: { data: { type: "subscriptions", id: subscription_id } },
        territory: { data: { type: "territories", id: CONFIG[:apple_territory] } }
      }
    }
  }
  client.post("v1/subscriptionIntroductoryOffers", payload)
  log("Apple: intro offer #{product[:trial_days]} ngày ✓")
rescue => e
  warn_step("Apple intro offer #{product[:product_id]}: #{api_error_message(e)}")
end

def apple_trial_duration(days)
  {
    3 => "THREE_DAYS",
    7 => "ONE_WEEK",
    14 => "TWO_WEEKS"
  }[days]
end

def ensure_apple_review_screenshot(client, subscription_id, product)
  screenshot_path = CONFIG[:review_screenshot]
  return if screenshot_path.nil? || screenshot_path.empty?

  path = File.expand_path(screenshot_path)
  unless File.file?(path)
    warn_step("Apple review screenshot #{product[:product_id]}: file không tồn tại #{path}")
    return
  end

  current = client.get("v1/subscriptions/#{subscription_id}/appStoreReviewScreenshot")
  screenshot = current["data"]
  unless screenshot
    payload = {
      data: {
        type: "subscriptionAppStoreReviewScreenshots",
        attributes: { fileName: File.basename(path), fileSize: File.size(path) },
        relationships: {
          subscription: { data: { type: "subscriptions", id: subscription_id } }
        }
      }
    }
    screenshot = client.post("v1/subscriptionAppStoreReviewScreenshots", payload).fetch("data")
  end

  state = screenshot.dig("attributes", "assetDeliveryState", "state")
  return if state == "COMPLETE"

  upload_apple_asset(
    client,
    path,
    screenshot,
    resource_type: "subscriptionAppStoreReviewScreenshots",
    update_path: "v1/subscriptionAppStoreReviewScreenshots/#{screenshot.fetch("id")}"
  )
  log("Apple: review screenshot #{product[:product_id]} ✓")
rescue => e
  warn_step("Apple review screenshot #{product[:product_id]}: #{api_error_message(e)}")
end

def upload_apple_asset(client, path, data, resource_type:, update_path:)
  (data.dig("attributes", "uploadOperations") || []).each do |operation|
    upload_operation_with_curl(operation, path)
  end

  checksum = Digest::MD5.file(path).hexdigest
  client.patch(
    update_path,
    {
      data: {
        type: resource_type,
        id: data.fetch("id"),
        attributes: { uploaded: true, sourceFileChecksum: checksum }
      }
    }
  )
end

def upload_operation_with_curl(operation, path)
  args = ["curl", "-sS", "--fail", "-X", operation.fetch("method", "PUT")]
  (operation["requestHeaders"] || []).each do |header|
    args += ["-H", "#{header.fetch("name")}: #{header.fetch("value")}"]
  end
  args += ["--upload-file", path, operation.fetch("url")]
  return if system(*args)

  raise "curl upload failed"
end

def apple_get_first_working(client, candidates)
  errors = []
  candidates.each do |path, query|
    return client.get(path, query)
  rescue => e
    errors << e.message
  end
  raise errors.join(" || ")
end

def money_vnd(amount)
  Google::Apis::AndroidpublisherV3::Money.new(
    currency_code: "VND",
    units: amount.to_s,
    nanos: 0
  )
end

def create_google_subscriptions
  key_path = ENV.fetch("SUPPLY_JSON_KEY")
  service = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
  service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(File.expand_path(key_path)),
    scope: "https://www.googleapis.com/auth/androidpublisher"
  )
  service.authorization.fetch_access_token!

  PRODUCTS.each do |product|
    ensure_google_subscription(service, product)
  end
rescue KeyError => e
  warn_step("Google Play: thiếu env #{e.key}. Bỏ qua Android.")
rescue => e
  warn_step("Google Play: #{api_error_message(e)}")
end

def ensure_google_subscription(service, product)
  package_name = CONFIG[:android_package]
  begin
    service.get_monetization_subscription(package_name, product[:product_id])
    log("Google Play: subscription #{product[:product_id]} đã tồn tại")
  rescue Google::Apis::ClientError => e
    raise unless e.status_code == 404

    service.create_monetization_subscription(
      package_name,
      google_subscription_object(product),
      product_id: product[:product_id],
      regions_version_version: CONFIG[:google_regions_version]
    )
    log("Google Play: đã tạo subscription #{product[:product_id]}")
  end

  begin
    service.activate_base_plan(
      package_name,
      product[:product_id],
      product[:base_plan_id],
      Google::Apis::AndroidpublisherV3::ActivateBasePlanRequest.new
    )
    log("Google Play: base plan #{product[:base_plan_id]} active ✓")
  rescue => e
    warn_step("Google Play activate #{product[:product_id]}: #{api_error_message(e)}")
  end

  ensure_google_trial_offer(service, product) if product[:trial_days].positive?
end

def google_subscription_object(product)
  base_plan = Google::Apis::AndroidpublisherV3::BasePlan.new(
    base_plan_id: product[:base_plan_id],
    auto_renewing_base_plan_type: Google::Apis::AndroidpublisherV3::AutoRenewingBasePlanType.new(
      billing_period_duration: product[:period],
      grace_period_duration: "P3D",
      resubscribe_state: "RESUBSCRIBE_STATE_ACTIVE"
    ),
    regional_configs: [
      Google::Apis::AndroidpublisherV3::RegionalBasePlanConfig.new(
        region_code: "VN",
        new_subscriber_availability: true,
        price: money_vnd(product[:price_vnd])
      )
    ]
  )

  Google::Apis::AndroidpublisherV3::Subscription.new(
    package_name: CONFIG[:android_package],
    product_id: product[:product_id],
    listings: [
      Google::Apis::AndroidpublisherV3::SubscriptionListing.new(
        language_code: "vi-VN",
        title: product[:title_vi],
        description: product[:description_vi],
        benefits: ["Không quảng cáo", "Soi vật nhiều hơn", "Lưu hành trình khám phá"]
      ),
      Google::Apis::AndroidpublisherV3::SubscriptionListing.new(
        language_code: "en-US",
        title: product[:title_en],
        description: product[:description_en],
        benefits: ["No ads", "More object discovery", "Saved discovery journeys"]
      )
    ],
    base_plans: [base_plan]
  )
end

def ensure_google_trial_offer(service, product)
  package_name = CONFIG[:android_package]
  offer_id = "trial-#{product[:trial_days]}d"
  offers = service.list_monetization_subscription_base_plan_offers(
    package_name,
    product[:product_id],
    product[:base_plan_id]
  )
  if offers.subscription_offers&.any? { |offer| offer.offer_id == offer_id }
    log("Google Play: offer #{offer_id} đã tồn tại")
    return
  end

  phase = Google::Apis::AndroidpublisherV3::SubscriptionOfferPhase.new(
    duration: "P#{product[:trial_days]}D",
    recurrence_count: 1,
    regional_configs: [
      Google::Apis::AndroidpublisherV3::RegionalSubscriptionOfferPhaseConfig.new(
        region_code: "VN",
        price: money_vnd(0)
      )
    ]
  )
  offer = Google::Apis::AndroidpublisherV3::SubscriptionOffer.new(
    package_name: package_name,
    product_id: product[:product_id],
    base_plan_id: product[:base_plan_id],
    offer_id: offer_id,
    phases: [phase],
    regional_configs: [
      Google::Apis::AndroidpublisherV3::RegionalSubscriptionOfferConfig.new(
        region_code: "VN",
        new_subscriber_availability: true
      )
    ]
  )

  service.create_monetization_subscription_base_plan_offer(
    package_name,
    product[:product_id],
    product[:base_plan_id],
    offer,
    offer_id: offer_id,
    regions_version_version: CONFIG[:google_regions_version]
  )
  service.activate_subscription_offer(
    package_name,
    product[:product_id],
    product[:base_plan_id],
    offer_id,
    Google::Apis::AndroidpublisherV3::ActivateSubscriptionOfferRequest.new
  )
  log("Google Play: tạo/activate offer #{offer_id} ✓")
rescue => e
  warn_step("Google Play offer #{product[:product_id]}: #{api_error_message(e)}")
end

if __FILE__ == $PROGRAM_NAME
  puts "WonderLens Plus product IDs:"
  puts "  yearly:  #{CONFIG[:yearly_id]}"
  puts "  monthly: #{CONFIG[:monthly_id]}"
  create_apple_subscriptions
  create_google_subscriptions
end
