import 'hero_catalog.dart';

/// Cấu hình cho một "capsule" onboarding. First-run và notification mission
/// dùng cùng màn hình, chỉ khác vật, copy, asset và việc có đánh dấu
/// `onboarding_seen` hay không.
class OnboardingMission {
  final String objectId;
  final String name;
  final String sceneAsset;
  final String cutoutAsset;
  final String stickerAsset;
  final String promptText;
  final String promptHint;
  final String promptAudio;
  final String resultAudio;

  const OnboardingMission({
    required this.objectId,
    required this.name,
    required this.sceneAsset,
    required this.cutoutAsset,
    required this.stickerAsset,
    required this.promptText,
    required this.promptHint,
    this.promptAudio = '',
    this.resultAudio = '',
  });

  static const OnboardingMission firstRun = OnboardingMission(
    objectId: 'paper_cup',
    name: 'Cốc giấy',
    sceneAsset: 'assets/images/onboarding_scene.jpg',
    cutoutAsset: 'assets/images/onboarding_cutout.png',
    stickerAsset: 'assets/images/paper_cup_cutout.png',
    promptText: 'Đố bé biết chiếc cốc này từ đâu tới?',
    promptHint: 'Chạm nút tròn bên dưới để chụp thử nhé!',
    promptAudio: 'assets/audio/paper_cup_onboarding_prompt.mp3',
    resultAudio: 'assets/audio/paper_cup_result.mp3',
  );

  static OnboardingMission forObjectId(String? rawObjectId) {
    final item = heroById((rawObjectId ?? '').trim());
    if (item == null) return firstRun;
    if (item.id == firstRun.objectId) return firstRun;

    // Chỉ vật có giọng Tuyết Trâm đóng gói mới trỏ tới asset; vật khác để trống
    // → onboarding rớt về TTS máy (speakAsset tự fallback).
    final hasAudio = heroesWithBundledAudio.contains(item.id);
    return OnboardingMission(
      objectId: item.id,
      name: item.name,
      sceneAsset: 'assets/images/mission_${item.id}_scene.jpg',
      cutoutAsset: heroCutoutAssetForId(item.id) ?? firstRun.cutoutAsset,
      stickerAsset: heroCutoutAssetForId(item.id) ?? firstRun.stickerAsset,
      promptText: 'Cùng soi ${_lowerObjectName(item.name)} hôm nay nhé!',
      promptHint: 'Chạm nút tròn để xem vật này được tạo ra thế nào.',
      promptAudio: hasAudio
          ? 'assets/audio/${item.id}_onboarding_prompt.mp3'
          : '',
      resultAudio: hasAudio
          ? 'assets/audio/${item.id}_onboarding_reveal.mp3'
          : '',
    );
  }

  /// Dùng trong local notification. Copy nói với phụ huynh, không gọi trẻ quay
  /// lại trực tiếp và không tạo áp lực kiểu streak/FOMO.
  String get notificationTitle => 'Hôm nay soi thử: $name';

  String get notificationBody =>
      'Cùng bé xem ${_lowerObjectName(name)} được tạo ra như thế nào nhé.';

  static String _lowerObjectName(String value) {
    if (value.isEmpty) return value;
    return value[0].toLowerCase() + value.substring(1);
  }
}
