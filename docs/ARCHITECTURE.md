# ENIGMA texnik arxitekturasi

## Birinchi amalga oshirish bosqichi

Birinchi bob — noma’lum xat ortidan kimsasiz temiryo‘l bekatiga kelish. Birinchi tayyorlanayotgan o‘ynaladigan kesim 4 muhitdan iborat: perron, kutish zali, bekat boshlig‘i xonasi va xizmat yerto‘lasi. Buyumlar, topilgan hujjatlar va mexanizmlar bitta izchil taraqqiyot zanjirini tashkil qiladi. Yakun — elektrsiz bekatga sirli poyezdning kelishi.

Joriy mahsulot butun 8–12 soatlik yetti bobli reliz deb taqdim etilmaydi. Qolgan boblarning rejasi ma’lumot bazasida saqlanadi; ularni o‘ynaladigan sahnalarga aylantirish, sinash va san’atini yaratish keyingi bosqichdir.

## Texnologiya va qatlamlar

- **Godot 4.6.3, GDScript, Compatibility renderer.** 2D kanvasda qatlamli 2.5D illyustratsiya va animatsiya; mobil GPU uchun katta 3D sahna va og‘ir postprocessing talab qilinmaydi.
- **O‘yin holati:** `scripts/core/game_state.gd` — markaziy holat, buyumlar, jumboq bayroqlari, maqsadlar, dalillar, tanlovlar va saqlash. UI holatning yagona manbai emas.
- **Taqdimot va o‘zaro aloqa:** `scripts/ui` — dasturiy ravishda yaratiladigan sahifa, dialog, inventar va jumboq boshqaruvlari. `scenes/main/main.tscn` kirish sahnasidir.
- **Muhit:** `scripts/world/station_art.gd` — to‘rtta joyning original protsedurali tasviri va atmosfera animatsiyasi. O‘yin mantig‘i tasvir chizish kodidan ajratiladi.
- **Ovoz:** `scripts/audio/soundscape.gd` — musiqa, yomg‘ir va 4 o‘rinli effekt puli, uchta mustaqil ovoz balandligi. Aktivlar `tools/generate_audio.py` orqali takrorlanuvchi yaratiladi.
- **Ma’lumot:** `data/` — boblar, buyumlar, dalillar, maxsus yashirin mazmun. `scripts/localization/localizer.gd` va `data/localization/uz.json` alohida til kataloglari, xavfsiz locale nomlari, zaxira o‘zbek matni hamda Godot TranslationServer ulanishini beradi. Hozir faqat o‘zbek tili katalogi bilan yetkaziladi.
- **Tekshiruv:** `tests/test_state.gd` markaziy holat va saqlashni, `tests/test_flow.gd` bobdagi real o‘zaro aloqalar va tugallashni tekshiradi. `tests/test_input.gd` sensor/mouse bosishidagi regressiyani, `tests/test_localization.gd` til kataloglari va zaxira matnni tekshiradi.

## Papkalar va zarur sahnalar

```text
project.godot                     # kirish sahnasi va mobil renderer
export_presets.cfg                # Android debug va Linux eksportlari
scenes/main/main.tscn             # bitta bosh sahna, UI dasturiy yaratiladi
scripts/core/                    # holat va taraqqiyot
scripts/ui/                      # menyu, inventar, jurnal, xarita, jumboqlar
scripts/world/                   # original muhit chizish va animatsiya
scripts/audio/                   # ovoz hayot sikli va ovoz balandligi
scripts/localization/            # kataloglar va TranslationServer ulanishi
assets/audio/                    # original WAV score, yomg‘ir, effektlar
assets/fonts/                    # o‘zbek yozuvini qo‘llovchi shrift/litsenziya
data/                            # buyum, dalil va yetti bob ma’lumoti
tests/                           # Godot bilan ishlaydigan test skriptlari
tools/install_godot.sh            # rasmiy SHA512 bilan vosita o‘rnatish
tools/configure_android.sh        # mashinaga xos SDK/JDK yo‘llari
tools/generate_audio.py           # original aktiv yaratish
.github/workflows/android.yml    # test → APK eksport → artifact
builds/                           # yaratiladigan, Gitga qo‘shilmaydigan fayllar
```

Amaldagi yordamchi skriptlar: `scripts/ui/hotspot_button.gd` xona hotspotlarining haqiqiy bosish hududlarini, `scripts/ui/inventory_button.gd` buyumning sudrash ma’lumotini, `scripts/ui/puzzle_art.gd` jumboqlarga xos tasvirni, `scripts/ui/main.gd` esa o‘yin oqimi va ekranlarni boshqaradi. Bosh sahna ichida yaratiladigan ko‘rinishlar: asosiy menyu, sozlamalar, bob tanlash, o‘yin HUD’i, buyum tavsifi, jurnal/hujjatlar, xarita, dalil doskasi, 3 darajali maslahat, har bir mexanizm paneli va bob yakuni.

Keyingi boblar uchun zarur kontent sahnalari: qasrning xonalari/yashirin zinapoya, kutubxona/arxiv, o‘rmon yo‘llari/qo‘riqxona, minora mexanizmlari, yerosti shahar/laboratoriya va markaziy xona/uch yakun. Ular reja bo‘lib, joriy paketda ishlaydigan sahnalar deb ko‘rsatilmaydi. Keyingi skript modullari personaj dialog grafi, ko‘p xona puzzle koordinatorlari, boblararo sahna yuklash, saqlash migratsiyasi va yakunlarni boshqarishni ajratib oladi; hozir birinchi bob mantig‘i sinovdan o‘tadigan mavjud qatlamlarda joylashadi.

Menyular, jumboq panellari, inventar va xona hotspotlari dasturiy yaratiladi; foydalanuvchi tugun yoki sahna yig‘maydi. Kelajakdagi boblar uchun xona sahnalari, personajlar, dialog ma’lumotlari va ko‘proq jumboq turlari mavjud yadro orqali ulanadi. Tugallanmagan bob uchun ishlamaydigan tugma yaratilmaydi.

## Birinchi bobning jumboq bog‘liqliklari

```text
Jadvaldagi 314 → chamadon → siniq soat va jez kalit
Xatdagi belgilar → shifrning 2–1–3 tartibi
Jez kalit → boshliq xonasi → 2–1–3 diskli shkaf → tishli g‘ildirak
Siniq soat + g‘ildirak → tiklangan soat → 21:15
21:15 devor soati → saqlagich
Saqlagich + yoqilgan/o‘chirilgan/yoqilgan kalitlar → elektr
Chipta + nam qayd → dalil xulosasi
Elektr + xulosa → signalning 0–2–1–0 ketma-ketligi → poyezd
```

Jumboq maqsadi, topiladigan dalili, javobi, mukofoti va saqlanadigan holati birgalikda tekshiriladi. Asosiy buyumlar tashlab yuborilmaydi. To‘g‘ri birlashtirish faqat mos juftlikni sarflaydi; boshqa urinish buyumni yo‘qotmaydi. Har bir joyga qaytish mumkin.

## Saqlash va oflayn ishlash

Holat JSON ko‘rinishida `user://` ichida saqlanadi, resurslar o‘yin paketida qoladi. Saqlangan ma’lumot yuklanishdan avval tekshiriladi; yaroqsiz fayldan zaxira nusxa orqali tiklanish ko‘zda tutiladi. HTTP, reklama SDK yoki majburiy akkaunt yo‘q. Inventar, jumboqlar, dalillar va sozlamalar saqlanadi. Keyingi boblar qo‘shilganda saqlash formatini versiyalash va migratsiya alohida testlardan o‘tishi kerak.

## San’at va ovoz ishlab chiqarish

Joriy kesim original protsedurali arxitektura, tuman/yomg‘ir, yoritilgan oynalar va mexanizm animatsiyalaridan foydalanadi. Bu random stock suratlar to‘plami emas. Qo‘lda yuqori detalda bo‘yalgan tijoriy fonlar, personaj portretlari, uzun kinematiklar va professional ovoz yozuvlari keyingi ishlab chiqarish hajmidir. Kelajakdagi aktivlar uchun manba, muallif, litsenziya, xom fayl va eksport o‘lchami alohida reyestrda saqlanadi. Vaziyatga mos rasm va ovozlar o‘yin ichidagi aniq hotspotlar bilan tekshiriladi.

Birinchi bob ranglari — tun ko‘ki, zumrad, antiqa oltin va fil suyagi. Keyingi boblar: qasr — bronza/binafsha; kutubxona — oltin/zumrad; o‘rmon — yashil/kumush; minora — mis/ko‘k; yerosti shahar — siyohrang/turkuaz; markaziy xona — oq oltin/qora ko‘k.

## Android optimallashtirish

- Landshaft, 1440×900 dizayn kanvasi, cho‘zilishga mos UI va katta bosish hududlari.
- Moslik renderer, qimmat hajmiy tuman yoki 3D yorug‘liksiz chizish.
- Tejamkor, muvozanatli va yuqori sifat sozlamalari zarracha/animatsiya yukini kamaytirishi kerak.
- Bir vaqtning o‘zida faqat joriy xona; ovoz effektlari cheklangan puldan foydalanadi.
- Import qilinadigan audio mono 22.05 kHz; original WAV manbalar kichik va oflayn.
- Android ARM64 + ARMv7, API 24+, target API 36. Haqiqiy minimum moslik qurilmada sinov talab qiladi.
- Redmi va boshqa real qurilmalarda sovuq start, issiqlik, 15–30 daqiqalik FPS, xotira, fon/oldinga qaytish, 16:9 va uzun ekranlar release mezonidir. Bularga eksportning o‘zi dalil bo‘la olmaydi.

## Qurish va ishonch

Vositalar rasmiy Godot GitHub release’idan TLS bilan yuklanadi va release SHA512 manifestiga solishtiriladi. CI rasmiy Android SDK va JDK bilan testlarni ishga tushiradi; muvaffaqiyatli testlardan so‘ng debug APK yaratadi va imzosini `apksigner` bilan tekshiradi. Release kalitlari manba kodida saqlanmaydi. Biror test hali ishlamagan bo‘lsa, statusda shunday yoziladi.
