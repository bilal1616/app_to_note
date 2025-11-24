#!/usr/bin/env bash

set -e  # Hata olursa script dursun

# 1. .env kontrolü
if [ ! -f ".env" ]; then
  echo "❌ .env bulunamadı. .env.example'dan kopyalayın."
  exit 1
fi

echo "✅ .env bulundu."

# 2. Flutter bağımlılıkları çek
echo "📦 flutter pub get çalıştırılıyor..."
flutter pub get

# 3. Supabase başlangıcı (opsiyonel - CLI mevcutsa)
if command -v supabase &> /dev/null; then
  echo "🚀 Supabase başlatılıyor (local dev)..."
  supabase start || echo "ℹ️ Supabase zaten çalışıyor olabilir"
else
  echo "ℹ️ Supabase CLI bulunamadı, atlanıyor."
fi

# 4. Flutter uygulamasını başlat
echo "🚀 Flutter uygulaması başlatılıyor..."
flutter run
