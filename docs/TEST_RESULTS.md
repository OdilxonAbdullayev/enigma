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
