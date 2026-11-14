# ENIGMA yig‘ish va Android APK olish

## Android telefondan GitHub orqali

1. Repozitoriyning **Actions → Android APK** bo‘limini oching.
2. `main` yoki `work` tarmog‘iga o‘zgarish yuborilganda yig‘ish avtomatik boshlanadi. Zarur bo‘lsa **Run workflow** ni bosing.
3. Barcha qadamlar yashil bo‘lgach, ish sahifasi pastidagi **Artifacts → enigma-android-debug** arxivini yuklab oling.
4. Arxivdagi `enigma-android-debug.apk` — o‘rnatish uchun fayl; `SHA256SUMS.txt` — uning nazorat yig‘indisi.
5. Telefon fayl boshqaruvchisida APKni oching. Android so‘rasa, shu fayl boshqaruvchiga noma’lum manbadan o‘rnatishga ruxsat bering.

GitHub hisobiga kirish kerak. Artifact odatda ZIP ko‘rinishida yuklanadi; APKni avval undan chiqaring. Artifact 30 kun saqlanadi. Workflow mavjudligi uning GitHub serverida allaqachon muvaffaqiyatli bajarilganini anglatmaydi; haqiqiy natijani Actions tarixidan tekshiring.

## Linuxdagi takrorlanuvchi yig‘ish

Godot **4.6.3.stable**, Python 3, curl, unzip, SHA512 vositasi, JDK 17 yoki 21 talab qilinadi. Android uchun SDK platform 36 va build-tools 36.1.0 kerak. Loyiha Internet talab qilmaydi; faqat vositalarni o‘rnatish vaqtida tarmoq zarur.

```sh
cd /workspace/enigma
export ENIGMA_TOOLS_DIR=/workspace/.tools/godot
export XDG_DATA_HOME=/workspace/.local/share
export XDG_CONFIG_HOME=/workspace/.local/config
export XDG_CACHE_HOME=/workspace/.local/cache
bash tools/install_godot.sh --templates
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --editor --import
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --script res://tests/test_state.gd
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --script res://tests/test_flow.gd
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --script res://tests/test_input.gd
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --script res://tests/test_localization.gd
mkdir -p builds
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --export-release Linux builds/enigma-linux.x86_64
```

Linux fayli ichiga o‘yin resurslari joylanadi; ishga tushirish uchun `chmod +x builds/enigma-linux.x86_64` va shu faylni ochish kifoya.

Android uchun rasmiy SDK Command-line Tools orqali `platform-tools`, `platforms;android-36`, `build-tools;36.1.0` o‘rnating va SDK litsenziyalarini qabul qiling. `tools/install_android_sdk.sh` Linuxda buni avtomatik bajaradi; u kerakli Android SDK litsenziyalarini qabul qiladi. Muhitdagi SDK yo‘lini ko‘rsating:

```sh
export ANDROID_HOME=/workspace/.tools/android-sdk
export ANDROID_USER_HOME=/workspace/.local/android
bash tools/install_android_sdk.sh
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
bash tools/configure_android.sh
"$ENIGMA_TOOLS_DIR/godot" --headless --path . --export-debug Android builds/enigma-android-debug.apk
"$ANDROID_HOME/build-tools/36.1.0/apksigner" verify --verbose builds/enigma-android-debug.apk
```

`JAVA_HOME` kompyuterdagi haqiqiy JDK joylashuviga mos bo‘lishi kerak. GitHub Actions uni avtomatik sozlaydi. `configure_android.sh` faqat foydalanuvchining lokal Godot muharrir yo‘llarini yangilaydi.

## Debug va release farqi

Debug APK sinash uchun avtomatik debug kalit bilan imzolanadi. CI shu test kalitini cache orqali keyingi yig‘malarda saqlashga harakat qiladi. Lokal yig‘ma va CI kalitlari yoki cache tiklanmagan yig‘malar kaliti farq qilishi mumkin. Android yangilash paytida imzo mos kelmasligini aytsa, eski test nusxasini o‘chirib qayta o‘rnatish kerak; bu mahalliy saqlashlarni ham o‘chiradi. O‘yinning keyingi barqaror relizlarida yagona xavfsiz release kalit ishlatiladi. U Google Play uchun tayyor tijoriy reliz emas. Release APK/AAB va do‘konga nashr qilish uchun ishlab chiquvchining maxfiy release keystore’i, Play hisob sozlamalari hamda maxfiylik hujjatlari kerak. Maxfiy kalit repozitoriyga qo‘shilmaydi. Hozirgi preset Gradle talab qilmaydigan APK eksportidan foydalanadi; AAB uchun alohida Gradle eksporti va xavfsiz release imzolash qo‘shilishi kerak.

APKning muvaffaqiyatli eksporti haqiqiy Android qurilmadagi sinov o‘rnini bosmaydi. Qurilma sinovlari, FPS, xotira, turli ekranlar va Redmi mosligi alohida tekshiriladi. Hozirgi bajarilgan va tekshirilmagan ishlar `DEVELOPMENT_STATUS.md` da qayd etiladi.
