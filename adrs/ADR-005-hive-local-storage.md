# ADR-005: Hive làm local storage

**Status:** Accepted  
**Date:** 2026-06-27

## Context

Cần lưu bộ sưu tập + huy hiệu locally trên device. Options: Hive, Drift (SQLite), SharedPreferences.

## Decision

**Hive** (NoSQL, pure Dart).

## Reasons

- Pure Dart, không cần native code setup phức tạp
- Nhanh hơn SQLite cho key-value + object store đơn giản
- API đơn giản, phù hợp data model (collection objects)
- Không cần schema migration phức tạp

## Consequences

- Không dùng Drift/SQLite
- Data model phải fit NoSQL (không join phức tạp — OK với collection đơn giản)
- Cần `hive_generator` + `build_runner` cho TypeAdapters
