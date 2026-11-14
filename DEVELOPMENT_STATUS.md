# Rivojlanish holati — v0.2.0

Bu hujjat rejalashtirilgan imkoniyatlarni bajarilgan deb hisoblamaydi.

## Yaratilgan birinchi bob

- Godot 4.6.3 loyihasi, dasturiy yaratiladigan sahna va interfeys.
- Asl chizmali to‘rtta joy: perron, kutish zali, boshliq xonasi, yerosti aloqa xonasi. Yomg‘ir, tuman, chiroqlar, chang, harakatlanuvchi poyezd.
- O‘zbekcha menyu, kirish xati, uch darajali yordam, xarita, kundalik, dalillar doskasi, tanaffus, mualliflar va litsenziyalar.
- Inventar: tavsif, tanlab ishlatish, buyum birlashtirish, sudrab qo‘yish yo‘li.
- To‘qqiz bog‘langan jumboq: jadval/jomadon → jez kalit/eshik; xat shifri → halqali shkaf → soatni tuzatish → katta soat → elektr tarmog‘i; chipta+nam yozuv → dalil xulosasi; tarmoq+xulosa → xotira signali.
- Malikning radio ovozi uchun matnli ikki tanlovli suhbat va saqlanadigan tanlov tarixi. Hozir tanlov keyingi bob voqealarini o‘zgartirmaydi.
- Ixtiyoriy yashirin tokcha/xotira parchasi, ma’lumot fayli orqali shaxsiy yashirin xat.
- Birinchi bobning yakuni: haydovchisiz poyezd. Bu to‘liq o‘yindagi uch yakundan biri emas.
- SHA-256 tekshiruvli atomik saqlash, oxirgi yaroqli zaxiradan tiklash, avtomatik va qo‘lda saqlash, davom etish.
- Mustaqil musiqa/tovush/muhit darajalari, uch sifat darajasi va 30/60 FPS chegarasi.
- Asl sintezlangan audio, DejaVu shriftlari, kengaytiriladigan JSON lokalizatsiya.
- Android va Linux eksport sozlamalari, tekshiriladigan vosita o‘rnatish skriptlari, APK yig‘uvchi GitHub Actions.

## Sinov dalillari

Godot 4.6.3, Linux x86_64 da `bash tools/test.sh` oxirgi ishga tushirilishi:

| Tekshiruv | Natija |
|---|---|
| Holat, bog‘liqliklar, saqlash buzilishi va zaxiradan tiklash | 250 tekshiruv, 0 xato |
| Lokalizatsiya, orqaga qaytish, parametrlar | 18 tekshiruv, 0 xato |
| Haqiqiy sahna tugmalari orqali birinchi bobning to‘liq yo‘li | 119 tekshiruv, 0 xato |
| Koordinatali bosish, sensor emulyatsiyasi, sudrash, ikki ekran nisbati | 156 tekshiruv, 0 xato |

Jami oxirgi jamlangan sinovda **543 tekshiruv, 0 xato**. Alohida X11/OpenGL kirish sinovi ham xatosiz o‘tdi. 1440×900 va 1920×864 virtual o‘lchamlarda joylashuv tekshirildi. Menyu, to‘rtta xona, qulf va poyezd tasvirlari haqiqiy renderdan olinib ko‘rib chiqildi. Virtual GPU VSync’ni almashtirishni qo‘llamaydi; bu telefondagi FPS haqida ma’lumot bermaydi.

Avtomatik topilgan va tuzatilgan xato: sensor orqali oynani yopish paytida tugun daraxtdan darhol uzilishi Godot kirish tarqatishiga xalaqit berardi. Endi yashirish va kechiktirilgan o‘chirish ishlatiladi; qayta sinov toza.

Yakuniy lokal eksportlar yaratildi: Android APK 57 504 299 bayt, Linux 72 158 664 bayt. APK `apksigner` v2/v3 tekshiruvidan o‘tdi; manifest API24/target36, ARM64/ARMv7. Paketdagi JSON kataloglari va litsenziyalar tekshirildi. Yakuniy eksport loglari xatosiz; eksportlangan Linux paketidagi sahna ishga tushishi va boshqarilgan yopilishi xatosiz sinovdan o‘tdi.

Manba `main` tarmog‘iga yuborildi. APK alohida `apk-v0.2.0` tarmog‘ida yuklab olinadi; bu GitHub Release yoki Play relizi emas. [APK olish](BUILD_INSTRUCTIONS.md). Yig‘ma natijalari va cheklovlar [TEST_RESULTS.md](docs/TEST_RESULTS.md) da.

## Bajarilmagan ishlar

- II–VII boblarning o‘ynaladigan sahnalari, mexanizmlari va voqealari. Yetti bob / 56 jumboqning ma’lumot dizayni mavjud: birinchi 9 tasi ishlaydi, qolgan 47 tasi `planned`.
- 8–12 soatlik to‘liq hikoya va uch xil yakun.
- Murakkab keyingi bob mexanizmlari: suriluvchi blok, bosim plitasi, tarixiy alifbo, ko‘p xonali vaqt mexanizmlari.
- Oqibatli ko‘p qahramonli suhbatlar, ko‘p saqlash uyasi, ochilgan boblarni mustaqil qayta o‘ynash.
- Rassom ishlagan yuqori aniqlikdagi yakuniy muhitlar, personajlar, professional aralashgan uzoq musiqa. Hozirgi original vektor chizmalar va qisqa sintezlangan kuylar yakuniy premium sifat deb taqdim etilmaydi.
- Bulut sinxronlash (asosiy o‘yin uchun zarur emas), reliz imzosi, AAB, Google Play nashri.

## Tekshirilmagan jihatlar

Haqiqiy Android/Redmi qurilmasi, o‘rnatish va to‘liq sensorli o‘yin sessiyasi, xotira/FPS/batareya/issiqlik, telefonning audio chiqishi, tizim fonga o‘tgandagi saqlash, turli kesikli ekranlar hali sinovdan o‘tmagan. Stol ustidagi sensor hodisasi emulyatsiyasi haqiqiy qurilma tekshiruvi emas.

GitHub Actions fayli va lokal eksport muvaffaqiyati GitHub serveridagi workflow bajarilganini anglatmaydi. Avtomatik qayta yig‘ish holatini Actions tarixidan tekshirish kerak. Google Play relizi deb belgilamang.
