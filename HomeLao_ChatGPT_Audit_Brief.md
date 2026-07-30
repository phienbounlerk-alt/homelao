# HomeLao — ເອກະສານສະຫຼຸບໂຄງການ ສຳລັບໃຫ້ AI ອື່ນກວດ

> ເອກະສານນີ້ຂຽນຂຶ້ນເພື່ອໃຫ້ AI ອື່ນ (ເຊັ່ນ ChatGPT) ທີ່ບໍ່ມີສິດເຂົ້າເຖິງ codebase ຫຼື database ຈິງ
> ສາມາດເຂົ້າໃຈໂຄງການ ແລະ ໃຫ້ຄຳແນະນຳ/ກວດສອບໄດ້ໂດຍບໍ່ຕ້ອງເບິ່ງໂຄ້ດ. ຂໍ້ມູນທັງໝົດອີງໃສ່ codebase ຈິງ
> (ອ່ານກົງຈາກໄຟລ໌ ແລະ Supabase schema) ໃນວັນທີ 28 ກໍລະກົດ 2026.

---

## 1. ພາບລວມໂຄງການ

**HomeLao** ເປັນແອັບ marketplace ອະສັງຫາລິມະຊັບ (ເຊົ່າ/ຂາຍ) ສຳລັບປະເທດລາວ ພ້ອມບໍລິການຂົນສົ່ງ/ຍ້າຍເຮືອນ
ຄູ່ຂະໜານ. ພາສາອິນເຕີເຟດເປັນພາສາລາວ 100%.

- **ແພລດຟອມ**: Flutter Web (deploy ຢູ່ GitHub Pages: `https://phienbounlerk-alt.github.io/homelao/`)
  — **ຍັງບໍ່ແມ່ນແອັບ native** ບໍ່ໄດ້ຂຶ້ນ App Store / Play Store
- **Backend**: Supabase (Postgres + Auth + Storage + Realtime), ໃຊ້ Row-Level Security (RLS) ເປັນຫຼັກ
  ໃນການຄວບຄຸມສິດເຂົ້າເຖິງຂໍ້ມູນ (ບໍ່ມີ backend server ແຍກຕ່າງຫາກ — client ຄຸຍກັບ Supabase ໂດຍກົງ)
- **CI/CD**: GitHub Actions → build → deploy ອັດຕະໂນມັດຂຶ້ນ GitHub Pages ທຸກຄັ້ງທີ່ push ເຂົ້າ `main`
- **Error tracking**: Sentry ເຊື່ອມຢູ່ທົ່ວແອັບ
- **Auth**: email + password ຜ່ານ Supabase Auth (ບໍ່ມີ OTP/SMS, ບໍ່ມີ OAuth/Google/Facebook login)

---

## 2. Tech Stack (ຈາກ pubspec.yaml ຈິງ)

| ໝວດ | ໄລບຣາຣີ |
|---|---|
| Backend client | `supabase_flutter` |
| Font/UI | `google_fonts` (Noto Sans Lao) |
| ຮູບພາບ | `image_picker` |
| Error tracking | `sentry_flutter` |
| ແຜນທີ່/GPS | `geolocator`, `flutter_map`, `latlong2`, `flutter_map_marker_cluster` |
| ອື່ນໆ | `shared_preferences`, `url_launcher`, `http` |
| Testing | `flutter_test`, `flutter_lints` |

**ບໍ່ມີ**: payment SDK ໃດໆ, push notification SDK (FCM/APNs), state management library ໃຫຍ່ (ບໍ່ໃຊ້ Riverpod/Bloc — ໃຊ້ `setState`/`StreamBuilder` ພື້ນຖານ), CI test coverage tool.

---

## 3. ໂຄງສ້າງຖານຂໍ້ມູນ (Supabase Public Schema — 15 ຕາຕະລາງ)

```
properties            — ລາຍການອະສັງຫາລິມະຊັບ (status: pending/approved/rejected, verified badge, featured, is_rented, expires_at)
profiles              — ຂໍ້ມູນຜູ້ໃຊ້
bookings              — ການນັດເບິ່ງຊັບສິນ
conversations         — ຫົວຂໍ້ແຊັດ (renter ↔ property owner)
messages              — ຂໍ້ຄວາມແຊັດ (sender_id, realtime-enabled)
favorites             — ຊັບສິນທີ່ບັນທຶກໄວ້
notifications         — ແຈ້ງເຕືອນ (realtime-enabled)
notification_prefs    — ການຕັ້ງຄ່າແຈ້ງເຕືອນຕໍ່ຜູ້ໃຊ້
reviews               — ຣິວິວ + ຄະແນນ (ມີ hidden/moderation)
review_helpful_votes  — ໂຫວດ "ເປັນປະໂຫຍດ" ໃນຣິວິວ
review_reports        — ລາຍງານຣິວິວບໍ່ເໝາະສົມ
drivers               — ຄົນຂັບ/ຜູ້ໃຫ້ບໍລິການຂົນສົ່ງ (status: pending/approved/rejected)
moving_requests        — ຄຳຂໍບໍລິການຍ້າຍເຮືອນ (status: pending/accepted/in_progress/completed/cancelled, ມີ GPS live tracking)
featured_requests      — ຄຳຂໍເຮັດໃຫ້ listing ຂຶ້ນເດັ່ນ (ຈ່າຍເງິນດ້ວຍມື, ເບິ່ງຂໍ້ 5)
owner_verifications    — ການຢືນຢັນຕົວຕົນເຈົ້າຂອງຊັບສິນ
analytics_events       — event log (view, favorite, phone_click, message, booking) — ໃຊ້ໂດຍ Owner Dashboard
```

ຄວາມປອດໄພຂໍ້ມູນອາໄສ RLS ຂອງ Postgres (ບໍ່ແມ່ນ application-layer authorization) — ທຸກຕາຕະລາງມີ policy
ຈຳກັດວ່າຜູ້ໃຊ້ໃດເຫັນ/ແກ້ໄຂແຖວໃດໄດ້. ມີການໃຊ້ `SECURITY DEFINER` RPC functions ສຳລັບ action ສະເພາະ
ທີ່ຕ້ອງການ bypass RLS ທົ່ວໄປແບບຄວບຄຸມໄດ້ (ຕົວຢ່າງ: toggle rented status, renew listing, hide review).

---

## 4. ຄຸນສົມບັດທີ່ສ້າງແລ້ວ (29 ໜ້າຈໍ)

### ຝັ່ງຜູ້ຊອກຫາທີ່ຢູ່ (Renter)
- ຄົ້ນຫາ + filter (ລາຄາ, ຫ້ອງນອນ, ທີ່ຕັ້ງ, parking, pet-friendly), pagination ຝັ່ງ server
- ຄົ້ນຫາຕາມແຜນທີ່ (bounding box + Haversine distance RPC)
- ລາຍລະອຽດຊັບສິນ, ຮູບຫຼາຍໃບ, ໂທຫາເຈົ້າຂອງ (`tel:` deep link), ບັນທຶກ favorite
- ນັດເບິ່ງຊັບສິນ (booking)
- ແຊັດ realtime ກັບເຈົ້າຂອງ
- ຂຽນ/ອ່ານຣິວິວ + ຄະແນນ
- ແຈ້ງເຕືອນ realtime (ອະນຸມັດ listing, ຂໍ້ຄວາມໃໝ່, ແລະອື່ນໆ) ພ້ອມຕັ້ງຄ່າເປີດ/ປິດຕໍ່ປະເພດ

### ຝັ່ງເຈົ້າຂອງຊັບສິນ (Owner)
- ລົງປະກາດ/ແກ້ໄຂ/ລຶບ listing (ຜ່ານຂະບວນການກວດສອບ admin ທຸກຄັ້ງທີ່ແກ້ໄຂ)
- ອັບໂຫລດຮູບ (Supabase Storage)
- ສະຫຼັບສະຖານະ "ໃຫ້ເຊົ່າແລ້ວ", ຕໍ່ອາຍຸປະກາດ (90 ວັນ)
- ຂໍໃຫ້ listing ຂຶ້ນເດັ່ນ (featured) — ຈ່າຍເງິນດ້ວຍມື ເບິ່ງຂໍ້ 5
- ຢືນຢັນຕົວຕົນ (owner verification)
- **Owner Dashboard**: KPI (ຍອດເບິ່ງ, ບັນທຶກ, ໂທ, ຂໍ້ຄວາມ, ນັດ, ລາຍໄດ້ໂດຍປະມານ, ອັດຕາການເຮັດ), ກຣາຟ
  ແນວໂນ້ມ (ວັນ/ອາທິດ/ເດືອນ/ປີ), ໜ້າຈັດການ bookings/messages/reviews ແຍກຕ່າງຫາກ

### ຝັ່ງບໍລິການຂົນສົ່ງ/ຍ້າຍເຮືອນ
- ລົງທະບຽນເປັນຄົນຂັບ (ຕ້ອງຖືກ admin ອະນຸມັດ)
- ຂໍບໍລິການຍ້າຍເຮືອນ, ຄົນຂັບຮັບວຽກ
- GPS live tracking ລະຫວ່າງວຽກ (ຜູ້ໃຊ້ເຫັນຕຳແໜ່ງຄົນຂັບເທິງແຜນທີ່ real-time)

### Admin
- ກວດອະນຸມັດ/ປະຕິເສດ: listings, drivers, featured requests
- ຄຸ້ມຄອງຣິວິວ (ເຊື່ອງ/ລາຍງານ)

### ອື່ນໆ
- Settings (ໂໝດສີ, ການແຈ້ງເຕືອນ, ປ່ຽນລະຫັດຜ່ານ), Help Center, ໜ້າເງື່ອນໄຂ/ຄວາມເປັນສ່ວນຕົວ (ເນື້ອຫາຈິງ 6 ພາກ, ບໍ່ແມ່ນ placeholder)

---

## 5. ຈຸດອ່ອນທີ່ຮູ້ແລ້ວ (ສຳຄັນສຳລັບການກວດ)

### 5.1 ການຈ່າຍເງິນ — ບໍ່ມີ payment gateway ອັດຕະໂນມັດ
"ຂຶ້ນເດັ່ນ" (featured listing, 50,000 ກີບ/7ວັນ, ຂໍ້ມູນຄົງທີ່ hardcode ໃນໂຄ້ດ) ໃຊ້ຂະບວນການດ້ວຍມືທັງໝົດ:
1. ຜູ້ໃຊ້ເຫັນເລກບັນຊີທະນາຄານ (BCEL) ໃນແອັບ
2. ໂອນເງິນເອງນອກແອັບ
3. ອັບໂຫລດຮູບສະລິບເປັນຫຼັກຖານ
4. Admin ເບິ່ງຮູບດ້ວຍຕາ ແລ້ວອະນຸມັດ/ປະຕິເສດດ້ວຍມື
5. ອະນຸມັດແລ້ວລະບົບອັດຕະໂນມັດຕັ້ງ `featured=true` + `featured_until`

**ຄວາມສ່ຽງ**: ບໍ່ມີການຢືນຢັນວ່າເງິນເຂົ້າຈິງ (ຮູບປອມແປງໄດ້), ບໍ່ scale, ຊັກຊ້າ, ບໍ່ມີ refund ອັດຕະໂນມັດ.

### 5.2 ບໍ່ແມ່ນແອັບ native
Flutter Web ເທົ່ານັ້ນ, ບໍ່ໄດ້ build ເປັນ iOS/Android app ແທ້, ບໍ່ຢູ່ App Store/Play Store.
ບໍ່ມີ push notification (FCM/APNs) — ແຈ້ງເຕືອນເຮັດວຽກສະເພາະຕອນເປີດແອັບຄ້າງໄວ້ (in-app realtime ຜ່ານ Supabase).

### 5.3 ການທົດສອບອັດຕະໂນມັດຈຳກັດ
ມີ test suite ນ້ອຍ (9 ໄຟລ໌ — ສ່ວນໃຫຍ່ເປັນ unit test ຂອງ model/widget ດ່ຽວໆ ເຊັ່ນ `property_test.dart`,
`review_test.dart`, `login_screen_test.dart`, `search_filters_test.dart`) — ບໍ່ມີ integration test
ຄອບຄຸມ flow ຕົ້ນຈົນຈົບ (ເຊັ່ນ: ລົງປະກາດ → admin ອະນຸມັດ → renter ຈອງ). ການທົດສອບຫຼັກອາໄສການທົດສອບ
ດ້ວຍມືຜ່ານ dev server/production ກ່ອນ deploy ແຕ່ລະຄັ້ງ.

### 5.4 ບໍ່ໄດ້ທົດສອບ
- Accessibility ຈິງ (VoiceOver/TalkBack) — ມີແຕ່ Semantics labels ໃນລະດັບໂຄ້ດ, ບໍ່ໄດ້ຟັງສຽງກວດຈິງ
- Cross-device/cross-browser ຈິງ (iOS Safari, Android Chrome ຫຼາຍລຸ້ນ) — ທົດສອບແຕ່ໃນ headless
  browser ຈຳລອງເທົ່ານັ້ນ
- ຄວາມທົນທານພາຍໃຕ້ traffic ຈິງ/concurrent users ຈຳນວນຫຼາຍ

### 5.5 ອື່ນໆ ທີ່ຄວນສັງເກດ
- ບໍ່ມີ email verification ບັງຄັບ ຫຼື 2FA
- ບໍ່ມີ rate limiting ຝັ່ງ application ນອກເໜືອຈາກທີ່ Supabase ໃຫ້ມາໂດຍພື້ນຖານ
- `analytics_events` ເປັນ event log ພື້ນຖານ — ບໍ່ແມ່ນລະບົບ analytics ເຕັມຮູບແບບ (ບໍ່ມີ funnel, cohort, ແລະອື່ນໆ)
- ຄ່າທຳນຽມ/ໄລຍະເວລາຂຶ້ນເດັ່ນ hardcode ໃນໂຄ້ດ Dart — ປ່ຽນຕ້ອງແກ້ໂຄ້ດ+deploy ໃໝ່ ບໍ່ມີໜ້າຕັ້ງຄ່າ

---

## 6. ຄຳຖາມທີ່ຢາກໃຫ້ AI ຊ່ວຍກວດ/ແນະນຳ

*(ແກ້ໄຂ/ຕັດອອກຕາມທີ່ຕ້ອງການ ກ່ອນສົ່ງໃຫ້ ChatGPT)*

1. ຄວນເລືອກ payment gateway ອັນໃດ ສຳລັບຕະຫຼາດລາວ (ເຊັ່ນ BCEL One API, LDB, ຫຼືອື່ນໆ) ແລະ ຂັ້ນຕອນ
   ປ່ຽນຈາກລະບົບດ້ວຍມືປັດຈຸບັນໄປສູ່ອັດຕະໂນມັດ ຄວນເປັນແນວໃດ?
2. ຄວນປ່ຽນ Flutter Web ເປັນ native app (iOS/Android) ຕອນນີ້ ຫຼືລໍຖ້າ? ຄວນເລີ່ມແນວໃດ (Flutter
   codebase ດຽວກັນ build native ໄດ້ຢູ່ແລ້ວ, ແຕ່ຕ້ອງມີ Apple Developer account, Google Play account,
   push notification setup)?
3. ຄວນເພີ່ມ test coverage ຈຸດໃດກ່ອນ ຖ້າມີເວລາ/ຄົນຈຳກັດ?
4. ມີຄວາມສ່ຽງດ້ານ security/privacy ອັນໃດແດ່ທີ່ເບິ່ງອອກຈາກໂຄງສ້າງນີ້ (ໂດຍສະເພາະ RLS-based
   authorization ໂດຍບໍ່ມີ backend server ແຍກຕ່າງຫາກ)?
5. ລຳດັບຄວາມສຳຄັນ (priority) ຄວນເປັນແນວໃດ ລະຫວ່າງ: payment gateway, native app, ການທົດສອບ,
   ຫຼືຄຸນສົມບັດໃໝ່ອື່ນໆ — ຖ້າເປົ້າໝາຍແມ່ນເປີດໃຫ້ຄົນທົ່ວໄປໃຊ້ຈິງພາຍໃນ 2-3 ເດືອນ?
