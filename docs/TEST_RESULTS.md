# Sinov dalillari

Sana: 2026-11-14. Linux x86_64, rasmiy Godot 4.6.3.stable.official.7d41c59c4, OpenGL Compatibility (tasvirlar uchun Mesa llvmpipe/Xorg virtual ekran).

`bash tools/test.sh` chiqish kodi **0**. Bu skript engine kodi 0 bo‘lsa ham `ERROR` / `SCRIPT ERROR` chiqishlarini xato deb hisoblaydi.

- `test_state.gd`: 250 tekshiruv, 0 xato.
- `test_localization.gd`: 18 tekshiruv, 0 xato.
- `test_flow.gd`: 119 tekshiruv, 0 xato. Tugmalarning haqiqiy callback’lari, barcha 9 jumboq, mukofotlar, davom etish, sozlamalar, kundalik, xarita, yakun tekshirilgan.
- `test_input.gd`: jamlangan oxirgi ishga tushirishda 156 tekshiruv, 0 xato. Koordinatalardan bosish va native mouse drag, Godot sensor emulyatsiyasi. Testdagi holatga qarab tugma mavjudligini qo‘shimcha tekshirishlar soni ozgina farqlanadi; 0 xato va butun yo‘l muhim.
- Qo‘shimcha X11/OpenGL kirish sinovi: o‘tdi. 1440×900 / 1920×864 virtual viewport. Telefon sinovi emas.
- `tools/capture_screenshots.gd`: menyu, perron, zal, boshliq xonasi, yerto‘la, qulf va kelayotgan poyezd haqiqiy Godot renderidan olingan; asosiy tasvirlar vizual ko‘rib chiqildi.

Manba o‘yin hech qanday tarmoq xizmatiga bog‘lanmaydi. Android manifestida Internet ruxsati yo‘q. Bu kuzatuv oflayn arxitekturani tasdiqlaydi; fizik telefondagi samolyot rejimi sinovi hali bajarilmagan.

## Audio va ishni tugatish

Audio tugunlarini to‘xtatib, oqimlarini bo‘shatib, mixer uchun navbatdagi kadrni kutish orqali lifecycle sinovi toza tugaydi. Godot’ni `--quit-after` orqali sahnani darhol buzib yopish 2 ta looping WAV playback havolasiga tegishli chiqish ogohlantirishini berishi mumkin; bu dvigatelning mixer tugash vaqti bilan bog‘liq alohida cheklov. Ishlayotgan o‘yin oqimida yoki to‘liq testlarda bunday xato kuzatilmadi.

## Qurilma va reliz mezonlari

Quyidagilar **bajarilmagan**: fizik Android qurilmaga o‘rnatish, Redmi sinovi, ARM runtime sessiyasi, audio chiqishi, back/fon/uyqu sikli, qurilmada FPS/xotira/issiqlik/batareya, Google Play imzolangan release APK/AAB, do‘kon relizi. 30/60 FPS sozlamasi shu tezlikka erishish kafolati emas.

Mahsulot yakuniy tijoriy reliz emas. Keyingi reliz mezonlari `ROADMAP.md` da.

## Yakuniy yig‘malar

Yig‘ilgan manba: `ea67e44f69d8c876bb831720a8de947b882d24f9`. Keyingi hujjat commitlari o‘yin kodini o‘zgartirmaydi.

| Fayl | Bayt | SHA256 |
|---|---:|---|
| enigma-android-debug.apk | 57504299 | c980edca886ad0d14f32425b368aedb156f7fd1bceb500bf650b8bb5a29bdd1b |
| enigma-linux.x86_64 | 72158664 | f56fa847498b63462083ac09e17d59db64761e6906c36c8e9d3d56e1f13a9150 |

APK `apksigner verify --verbose` v2/v3 imzosidan o‘tdi. `aapt dump badging` paket nomi `org.enigma.forgottenworld`, v0.2.0, min24/target36, ARM64+ARMv7 ni tasdiqladi. APKdagi barcha JSON, lokalizatsiya, shrift va litsenziya fayllari tekshirildi. Yakuniy eksportlar xatosiz.

Eksportlangan Linux binarining ichki PCK resurslari `godot --main-pack builds/enigma-linux.x86_64 --script /tmp/enigma_packed_smoke.gd` orqali ishga tushirildi: bosh sahna, shriftlar, UI, audio va lokalizatsiya yuklandi, audio mixerga vaqt berib yopildi, xato/ogohlantirish bo‘lmadi. Bu Linuxdagi paket sinovi; ARM qurilmada ishlashni tasdiqlamaydi.
