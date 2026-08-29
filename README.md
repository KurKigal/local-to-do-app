# FlowTask

FlowTask, günlük görevleri hızlı ve sade biçimde yönetmek için geliştirilen **Flutter tabanlı modern bir To-Do uygulamasıdır**.

Projenin temel hedefi; görev ekleme, düzenleme ve tamamlama gibi klasik yapılacaklar listesi özelliklerini; **öncelik, proje, etiket, tekrar, filtreleme, ana ekran widget'ı ve deep link desteği** gibi daha gelişmiş özelliklerle birleştirmektir.

> FlowTask halen aktif olarak geliştirilmektedir. Bazı özellikler tamamlanmış, bazıları ise ürün deneyimini güçlendirmek amacıyla geliştirilmeye devam etmektedir.

---

## İçindekiler

- [Özellikler](#özellikler)
- [Uygulama Yaklaşımı](#uygulama-yaklaşımı)
- [Priority Sistemi](#priority-sistemi)
- [Android Widget](#android-widget)
- [Deep Link ve Routing](#deep-link-ve-routing)
- [Proje Yapısı](#proje-yapısı)
- [Kurulum](#kurulum)
- [Geliştirme](#geliştirme)
- [Testler](#testler)
- [Build Alma](#build-alma)
- [Yol Haritası](#yol-haritası)
- [Katkı](#katkı)
- [Lisans](#lisans)

---

# Özellikler

## Görev Yönetimi

FlowTask'in merkezinde görev yönetimi bulunur.

Desteklenen temel akışlar:

- Yeni görev oluşturma
- Görev düzenleme
- Görev tamamlama
- Görev detaylarını görüntüleme
- Tarihe göre görevleri yönetme
- Bugünkü görevleri görüntüleme
- Görevleri filtreleme
- Görevleri projelere ayırma
- Görevlere etiket ekleme
- Görevlere öncelik atama
- Tekrarlayan görevler oluşturma

---

## Today Ekranı

`Today` görünümü kullanıcının o gün odaklanması gereken görevleri tek noktada toplamak için tasarlanmıştır.

Bu ekranın amacı yalnızca bugünün tarihine sahip görevleri göstermek değil; zaman içerisinde aşağıdaki sinyalleri birlikte değerlendiren daha akıllı bir odak ekranına dönüşmektir:

- Son tarihi bugün olan görevler
- Gecikmiş görevler
- Yüksek öncelikli görevler
- Yaklaşan görevler
- Tekrarlayan görevler

---

## Projeler

Görevler farklı projeler altında gruplanabilir.

Örnek kullanım:

```text
Kişisel
İş
FlowTask
Okul
Alışveriş
```

Görev oluşturma veya düzenleme sırasında proje seçimi için ayrı bir seçim arayüzü kullanılır.

İlgili bileşen:

```text
lib/features/tasks/ui/widgets/project_picker_sheet.dart
```

---

## Etiketler

Görevler bir veya daha fazla anlamlı kategoriyle ilişkilendirilebilir.

Örnek etiketler:

```text
#flutter
#backend
#acil
#ev
#araştırma
```

Etiket seçimi için özel bir picker bileşeni bulunur:

```text
lib/features/tasks/ui/widgets/tag_picker_sheet.dart
```

---

## Görev Filtreleme

Kullanıcıların görev listelerini ihtiyaçlarına göre daraltabilmesi için filtreleme altyapısı bulunmaktadır.

Filtreleme ekranı:

```text
lib/features/tasks/ui/widgets/task_filter_sheet.dart
```

Filtre sistemi zaman içerisinde aşağıdaki kriterleri destekleyecek şekilde genişletilebilir:

- Durum
- Tarih
- Priority
- Proje
- Etiket
- Tekrarlama durumu

---

## Tekrarlayan Görevler

FlowTask, düzenli aralıklarla tekrar eden görevlerin yönetilebilmesi için recurrence yapısına sahiptir.

Tekrar ayarlarının düzenlendiği arayüz:

```text
lib/features/tasks/ui/widgets/recurrence_editor_sheet.dart
```

Örnek tekrar senaryoları:

```text
Her gün
Her hafta
Her ay
Belirli günlerde
Özel tekrar düzeni
```

---

# Uygulama Yaklaşımı

FlowTask yalnızca bir görev listesi olmak yerine kullanıcının **neye odaklanması gerektiğini daha hızlı anlamasını sağlayan** bir görev yönetim aracı olarak geliştirilmektedir.

Temel ürün yaklaşımı:

```text
Task
 ├── Due Date
 ├── Priority
 ├── Project
 ├── Tags
 ├── Recurrence
 └── Completion State
```

Bu bilgiler farklı ekranlarda bir araya getirilerek daha anlamlı bir görev deneyimi oluşturur.

---

# Priority Sistemi

Görevler öncelik seviyelerine sahip olabilir.

Önerilen temel model:

```dart
enum TaskPriority {
  none,
  low,
  medium,
  high,
}
```

Priority'nin amacı yalnızca görev kartında renk veya ikon göstermek değildir.

Uzun vadede priority değerinin uygulamanın davranışını etkilemesi hedeflenmektedir.

Örneğin:

- Yüksek öncelikli görevleri öne çıkarma
- Priority bazlı sıralama
- Priority filtresi
- Today ekranında önemli görevleri vurgulama
- Widget sıralamasında priority kullanma
- Akıllı `Focus` listesi oluşturma

Priority ile deadline kavramları birbirinden ayrılmalıdır.

```text
Priority = Kullanıcının verdiği önem

Urgency = Tarih ve deadline üzerinden hesaplanan aciliyet
```

Örnek:

```text
High + Overdue   → Kritik
High + Today     → Güçlü vurgu
Low + Overdue    → Gecikmiş
High + No Date   → Önemli
None + Today     → Bugün yapılmalı
```

Bu yaklaşım ileride görevlerin otomatik olarak skorlanmasına olanak sağlar.

Örnek scoring mantığı:

```text
High priority     +30
Medium priority   +15
Low priority       +5

Overdue           +40
Due today         +25
Due tomorrow      +10
```

Bu skor kullanıcıya doğrudan gösterilmek zorunda değildir. Görev sıralama ve `Focus` gibi smart-list özelliklerinde kullanılabilir.

---

# Android Widget

FlowTask, Android ana ekran widget desteğine sahiptir.

Widget tarafında amaç uygulamayı açmadan temel görev aksiyonlarına hızlı erişim sağlamaktır.

Desteklenen veya planlanan temel widget aksiyonları:

- Today ekranını açma
- Yeni görev oluşturma
- Belirli bir görevi açma
- Görevi tamamlandı olarak işaretleme

Android tarafında widget provider bulunmaktadır:

```text
FlowTaskWidgetProvider.kt
```

Widget metadata:

```text
flowtask_widget_info.xml
```

Widget picker içerisinde gerçekçi bir önizleme göstermek amacıyla statik preview kaynakları kullanılmaktadır.

Tasarım yaklaşımında AMOLED ekranlarla uyumlu koyu bir görünüm hedeflenmektedir.

---

# Deep Link ve Routing

Widget ve uygulama arasında çalışan aksiyonların doğru ekrana yönlendirilmesi için merkezi URI/deep-link mapping yapısı kullanılmaktadır.

Örnek intent senaryoları:

```text
Today
New Task
Open Task
Complete Task
```

Widget üzerinden gelen URI'lar doğrudan router'a gönderilmeden önce uygulamanın anlayabileceği route'lara dönüştürülür.

İlgili yapı:

```text
flowtask_widget_link.dart
```

Routing tarafında güvenli fallback davranışı bulunmaktadır.

Örneğin geçersiz veya desteklenmeyen bir rota alınırsa uygulama güvenli biçimde:

```text
/today
```

ekranına yönlendirilebilir.

Root route (`/`) için de güvenli redirect mantığı uygulanmaktadır.

---

# Proje Yapısı

Proje feature-oriented bir Flutter klasör yapısı kullanmaktadır.

Mevcut yapının önemli bölümleri yaklaşık olarak şöyledir:

```text
flowtask/
│
├── android/
│   └── ...
│
├── lib/
│   │
│   ├── core/
│   │   ├── utils/
│   │   └── ...
│   │
│   ├── features/
│   │   └── tasks/
│   │       ├── ...
│   │       └── ui/
│   │           └── widgets/
│   │               ├── project_picker_sheet.dart
│   │               ├── recurrence_editor_sheet.dart
│   │               ├── tag_picker_sheet.dart
│   │               └── task_filter_sheet.dart
│   │
│   ├── main.dart
│   └── ...
│
├── test/
│   └── ...
│
├── README.md
├── pubspec.yaml
└── ...
```

> Klasör yapısı geliştirme sürecinde yeni feature ve domain katmanlarıyla genişleyebilir.

---

# Mimari Prensipler

Projede geliştirme yaparken aşağıdaki prensiplerin korunması hedeflenmektedir.

## Feature bazlı organizasyon

Bir özelliğe ait kod mümkün olduğunca aynı feature altında tutulmalıdır.

Örneğin:

```text
features/tasks/
```

Bu yaklaşım uygulama büyüdükçe dosyaların yönetilebilir kalmasını sağlar.

---

## Tek sorumluluk

Picker, editor veya filtreleme gibi karmaşık UI parçaları ana ekran widget'larına gömülmek yerine ayrı bileşenlerde tutulur.

Örnek:

```text
project_picker_sheet.dart
tag_picker_sheet.dart
recurrence_editor_sheet.dart
task_filter_sheet.dart
```

---

## Güvenli routing

Harici URI, widget intent veya deep link değerleri doğrudan navigation katmanına aktarılmamalıdır.

Önce doğrulanmalı ve uygulama içi güvenli bir route'a çevrilmelidir.

---

## Test edilebilirlik

Routing, URI mapping ve iş mantığı mümkün olduğunca UI'dan ayrılarak unit/widget testleriyle doğrulanabilir tutulmalıdır.

---

# Kurulum

Projeyi klonlayın:

```bash
git clone <repository-url>
cd flowtask
```

Flutter bağımlılıklarını yükleyin:

```bash
flutter pub get
```

Flutter ortamını kontrol edin:

```bash
flutter doctor
```

Uygulamayı çalıştırın:

```bash
flutter run
```

---

# Geliştirme

Kod analizini çalıştırmak için:

```bash
flutter analyze
```

Otomatik formatlama:

```bash
dart format .
```

Testleri çalıştırmak için:

```bash
flutter test
```

---

# Testler

Projede özellikle routing ve widget bağlantılarında regression testlerine önem verilmektedir.

Test edilmesi gereken temel senaryolar:

## Routing

- `/` rotasının güvenli redirect vermesi
- Geçersiz route fallback'i
- Today route
- New Task route
- Task detail route

## Widget intent

- Today tıklaması
- New Task tıklaması
- Task open tıklaması
- Done tıklaması

## Uygulama durumu

Widget aksiyonlarının hem:

```text
Cold Start
```

hem de:

```text
Warm Start
```

durumlarında çalışması doğrulanmalıdır.

---

# Build Alma

## Debug APK

```bash
flutter build apk --debug
```

## Release APK

```bash
flutter build apk --release
```

Release build öncesinde aşağıdaki kontrollerin yapılması önerilir:

```bash
flutter analyze
flutter test
flutter build apk --release
```

---

# Widget Manuel Test Kontrol Listesi

Widget geliştirmeleri emulator veya gerçek cihaz üzerinde manuel olarak da doğrulanmalıdır.

Kontrol listesi:

- Widget picker preview doğru görünüyor mu?
- Widget ana ekrana sorunsuz ekleniyor mu?
- Today aksiyonu doğru ekranı açıyor mu?
- New Task aksiyonu doğru ekranı açıyor mu?
- Görev tıklaması doğru task detayına gidiyor mu?
- Done aksiyonu görev durumunu doğru güncelliyor mu?
- Cold start sırasında navigation düzgün çalışıyor mu?
- Warm start sırasında navigation düzgün çalışıyor mu?
- Geçersiz URI uygulamayı crash ettiriyor mu?
- Widget görünümü AMOLED/koyu temada okunabilir mi?

---

# Geliştirme Yol Haritası

FlowTask için düşünülen geliştirmeler:

## Priority'yi işlevsel hale getirme

- [ ] Priority-aware sorting
- [ ] Priority filtreleri
- [ ] High priority görev vurgusu
- [ ] Priority + due-date scoring
- [ ] Widget priority sıralaması

## Smart Lists

- [ ] Important
- [ ] Urgent
- [ ] Focus
- [ ] Someday

Örnek:

```text
Important
→ High priority görevler

Urgent
→ Bugün bitmesi gereken veya gecikmiş görevler

Focus
→ High priority veya urgent görevler

Someday
→ Low priority ve tarihi olmayan görevler
```

## Widget

- [ ] Widget aksiyonlarının tüm cihaz durumlarında doğrulanması
- [ ] Priority indicator
- [ ] Daha gelişmiş widget görünümü
- [ ] Widget configuration seçenekleri

## Filtreleme

- [ ] Priority filtresi
- [ ] Project filtresi
- [ ] Tag filtresi
- [ ] Due-date filtresi
- [ ] Çoklu filtre kombinasyonları

## Test

- [ ] Daha geniş unit test kapsamı
- [ ] Widget testleri
- [ ] Routing regression testleri
- [ ] Deep-link edge-case testleri
- [ ] Integration testleri

---

# Git Workflow

Yeni bir geliştirme öncesinde güncel branch'i çekmek:

```bash
git pull
```

Değişiklikleri kontrol etmek:

```bash
git status
```

Dosyaları stage etmek:

```bash
git add .
```

Commit oluşturmak:

```bash
git commit -m "feat: add task priority sorting"
```

Remote'a göndermek:

```bash
git push
```

Önerilen Conventional Commit örnekleri:

```text
feat: add task priority sorting
fix: handle invalid widget deep links
test: add routing regression tests
refactor: extract widget URI mapper
docs: update README
style: improve task card layout
```

---

# Tasarım Hedefleri

FlowTask geliştirilirken aşağıdaki ürün prensiplerinin korunması amaçlanmaktadır:

- Hızlı görev oluşturma
- Minimum gereksiz etkileşim
- Temiz ve modern arayüz
- Koyu tema / AMOLED uyumu
- Bilgiyi kalabalıklaştırmadan gösterme
- Kullanıcının önemli görevleri hızlı fark etmesi
- Widget üzerinden temel işlemleri mümkün olduğunca hızlı yapabilme

---

# Projenin Vizyonu

FlowTask'in uzun vadeli hedefi yalnızca:

> "Yapılacak işleri listeleyen bir uygulama"

olmak değildir.

Amaç:

> Kullanıcının bugün neye odaklanması gerektiğini hızlı biçimde belirleyen, görevleri bağlamına göre organize eden ve mümkün olduğunca az sürtünmeyle aksiyon almasını sağlayan kişisel görev yönetim sistemi oluşturmaktır.

Bu nedenle proje; priority, due date, recurrence, tags, projects, smart lists ve widget gibi özellikleri birbirinden bağımsız seçenekler olarak değil, tek bir görev yönetim deneyiminin parçaları olarak ele almaktadır.

---

# Katkı

Proje aktif geliştirme aşamasındadır.

Yeni bir özellik eklerken mümkün olduğunca:

1. Mevcut mimariyi koruyun.
2. İş mantığını UI'dan ayırın.
3. Edge-case'leri düşünün.
4. Test ekleyin.
5. `flutter analyze` çalıştırın.
6. `flutter test` çalıştırın.
7. Commit mesajlarını açık ve anlamlı yazın.

---

# Lisans

Lisans bilgisi henüz belirlenmediyse proje özel kullanım kapsamında tutulabilir.

Açık kaynak olarak yayınlanacaksa bu bölüm uygun lisans bilgisiyle güncellenmelidir.

Örnek:

```text
MIT License
```

---

<p align="center">
  <strong>FlowTask</strong><br>
  Daha az karmaşa. Daha net odak.
</p>
