import 'package:flutter/material.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';

class ScreeningCategory {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<String> questions;
  final Map<String, List<String>> recommendations; // keys: 'doctor', 'medication', 'nutrition', 'remedies', 'exercise'

  ScreeningCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.questions,
    required this.recommendations,
  });
}

class SpecializedScreeningScreen extends StatefulWidget {
  const SpecializedScreeningScreen({super.key});

  @override
  State<SpecializedScreeningScreen> createState() => _SpecializedScreeningScreenState();
}

class _SpecializedScreeningScreenState extends State<SpecializedScreeningScreen> {
  final List<ScreeningCategory> _categories = [
    ScreeningCategory(
      id: "pcos",
      title: "PCOS Risk Assessment",
      description: "Screen for Polycystic Ovary Syndrome, covering cycle regularity, hormonal balances, and physical indicators.",
      icon: Icons.bubble_chart_outlined,
      questions: [
        "Are your menstrual cycles consistently irregular, missed, or abnormally long?",
        "Do you experience excess hair growth on your face, chin, chest, or abdomen (hirsutism)?",
        "Do you have severe adult acne or extremely oily skin that persists despite treatment?",
        "Have you experienced rapid weight gain, particularly around your abdomen, or find it exceptionally hard to lose weight?",
        "Have you noticed thinning hair on your scalp or male-pattern hair loss?",
        "Have you experienced difficulty getting pregnant or been diagnosed with ovarian cysts?",
        "Do you have a family history of PCOS, type-2 diabetes, or insulin resistance?",
      ],
      recommendations: {
        "doctor": [
          "Schedule a consultation with a Gynecologist or Endocrinologist.",
          "Request a pelvic ultrasound to screen for polycystic ovaries.",
          "Order a serum hormone panel (LH, FSH, Free/Total Testosterone, DHEA-S).",
          "Conduct a fasting blood glucose and insulin resistance (HOMA-IR) test."
        ],
        "medication": [
          "Combined Oral Contraceptive Pills (to regulate cycles and lower excess androgens).",
          "Metformin (if insulin resistance is detected, to enhance insulin sensitivity).",
          "Spironolactone (anti-androgen medication, if severe hirsutism or acne is present).",
          "Inositol supplements (Myo-Inositol & D-Chiro-Inositol) to support ovulation."
        ],
        "nutrition": [
          "Adopt a Low Glycemic Index (GI) diet to stabilize insulin levels (whole grains, oats, quinoa).",
          "Increase fiber intake to promote healthy gut flora and slow carbohydrate absorption.",
          "Integrate anti-inflammatory foods (turmeric, wild-caught salmon, berries).",
          "Drink spearmint tea (research shows 2 cups daily helps reduce free testosterone)."
        ],
        "remedies": [
          "Take Apple Cider Vinegar (1 tbsp in warm water before meals) to boost insulin sensitivity.",
          "Practice seed cycling (consuming flax/pumpkin seeds first half of cycle, sesame/sunflower seeds second half).",
          "Ensure adequate Vitamin D3 + K2 intake to regulate metabolic functions."
        ],
        "exercise": [
          "Focus on Strength & Resistance Training (2-3 times/week) to build muscle mass and burn excess glucose.",
          "Perform High-Intensity Interval Training (HIIT) to improve cardiovascular health and combat insulin resistance.",
          "Include gentle walks (10-15 minutes) immediately after meals to lower postprandial glucose spikes."
        ]
      }
    ),
    ScreeningCategory(
      id: "breast_cancer",
      title: "Breast Cancer Screening Guide",
      description: "Assess risks based on age, physiological symptoms, and genetic/familial history.",
      icon: Icons.favorite_border_rounded,
      questions: [
        "Are you over 40 years old?",
        "Have you felt any painless lumps, localized thickening, or hard swelling in your breasts or underarm areas?",
        "Have you noticed dimpling, puckering, redness, or an orange-peel texture on the skin of either breast?",
        "Have you experienced nipple changes, such as sudden retraction, inversion, or spontaneous discharge (especially bloody)?",
        "Do you have a first-degree biological relative (mother, sister, daughter) diagnosed with breast or ovarian cancer?",
        "Have you or an immediate family member tested positive for BRCA1 or BRCA2 genetic mutations?",
        "Have you previously had a breast biopsy showing atypical hyperplasia or another high-risk lesion?",
      ],
      recommendations: {
        "doctor": [
          "Consult a general physician or oncologist immediately for a clinical breast exam (CBE).",
          "Schedule a screening mammogram (especially if over 40) or diagnostic mammogram.",
          "Undergo a breast ultrasound or MRI for dense breast tissue visualization.",
          "Seek genetic counseling if there is a strong BRCA1/BRCA2 family history."
        ],
        "medication": [
          "For high-risk individuals, discuss Selective Estrogen Receptor Modulators (SERMs) like Tamoxifen.",
          "Discuss Aromatase Inhibitors (e.g., Anastrozole) for chemoprevention in postmenopausal high-risk women.",
          "Avoid prolonged, unmonitored Hormone Replacement Therapy (HRT)."
        ],
        "nutrition": [
          "Consume antioxidant-rich cruciferous vegetables (broccoli, cabbage, Brussels sprouts, kale).",
          "Increase intake of dietary lignans (ground flaxseeds) and omega-3 fatty acids (walnuts, chia seeds).",
          "Limit or completely avoid alcohol consumption, as it is directly linked to increased risk.",
          "Reduce consumption of processed meats, refined sugars, and trans fats."
        ],
        "remedies": [
          "Perform a Breast Self-Exam (BSE) monthly, 3-5 days after your period ends.",
          "Avoid endocrine-disrupting chemicals found in plastics (BPA) and parabens in cosmetic products.",
          "Maintain a healthy body weight, as postmenopausal obesity increases estrogen production."
        ],
        "exercise": [
          "Maintain moderate-intensity aerobic exercise (such as brisk walking, swimming, or cycling) for 150 minutes per week.",
          "Engage in full-body stretching and yoga to promote lymphatic drainage.",
          "Perform regular physical activity to lower circulating insulin and estrogen levels."
        ]
      }
    ),
    ScreeningCategory(
      id: "endometriosis",
      title: "Endometriosis Risk Assessment",
      description: "Analyze indicators for pelvic growths, menstrual cramps, and chronic pelvic pain.",
      icon: Icons.spa_outlined,
      questions: [
        "Do you experience severe, debilitating pelvic pain and cramps during your periods (dysmenorrhea)?",
        "Do you suffer from chronic lower back or pelvic pain that occurs outside your period?",
        "Do you experience deep pain during or immediately after sexual intercourse?",
        "Do you experience painful bowel movements or painful urination, particularly during your period?",
        "Do you have very heavy menstrual flows (menorrhagia) or bleed/spot between your periods?",
        "Have you had difficulty conceiving or been diagnosed with unexplained infertility?",
        "Do you experience severe fatigue, bloating, diarrhea, constipation, or nausea during your periods?",
      ],
      recommendations: {
        "doctor": [
          "Consult a Gynecologist specializing in Endometriosis/Chronic Pelvic Pain.",
          "Request a specialized transvaginal ultrasound or pelvic MRI.",
          "Discuss diagnostic laparoscopy (the definitive gold standard for detecting endometriosis lesions)."
        ],
        "medication": [
          "Nonsteroidal Anti-inflammatory Drugs (NSAIDs like Ibuprofen or Naproxen) to manage pain.",
          "Hormonal therapies (oral contraceptives, progestin-only pills, or GnRH agonists) to suppress ovulation.",
          "Aromatase inhibitors to reduce estrogen levels locally within endometriosis implants."
        ],
        "nutrition": [
          "Follow a strict anti-inflammatory diet (rich in olive oil, leafy greens, fatty fish).",
          "Significantly increase gluten-free grains if experiencing bowel symptoms ('endo-belly').",
          "Limit inflammatory triggers like red meat, caffeine, dairy, and gluten.",
          "Incorporate ginger, turmeric, and magnesium-rich foods to relax smooth muscles."
        ],
        "remedies": [
          "Use targeted heat therapy (hot water bottles, heating pads) to relieve uterine and pelvic spasms.",
          "Try warm Epsom salt baths (magnesium absorbs through the skin to relax muscles).",
          "Apply pelvic castor oil packs (external warm packs) to stimulate local circulation and ease pain."
        ],
        "exercise": [
          "Practice gentle pelvic floor stretching and diaphragmatic breathing to release tight pelvic muscles.",
          "Incorporate low-impact exercises like swimming, walking, or Pilates to boost endorphins.",
          "Engage in restorative yoga poses (e.g., Child's Pose, Reclined Cobbler's Pose) to alleviate spasms."
        ]
      }
    ),
    ScreeningCategory(
      id: "thyroid",
      title: "Thyroid Disorders Assessment",
      description: "Screen for symptoms of Hypothyroidism or Hyperthyroidism, checking energy levels, weight changes, and temperature tolerances.",
      icon: Icons.grain_outlined,
      questions: [
        "Have you experienced sudden, unexplained weight gain (despite no diet changes) or extreme difficulty losing weight?",
        "Do you feel constantly fatigued, sluggish, and sleep-deprived despite sleeping 8+ hours?",
        "Are you extremely sensitive to cold (feeling chilled when others are warm) or intolerant to heat?",
        "Do you experience regular brain fog, difficulty concentrating, or sudden mood swings (anxiety/depression)?",
        "Have you noticed dry, coarse skin, thinning hair, or brittle nails?",
        "Do you experience persistent muscle weakness, joint aches, or slow heart rate?",
        "Have you noticed swelling or tightness in the front of your neck (enlarged thyroid/goiter)?",
      ],
      recommendations: {
        "doctor": [
          "Consult an Endocrinologist or primary care physician.",
          "Order a comprehensive Thyroid Panel (TSH, Free T4, Free T3, and Thyroid Antibodies like TPO).",
          "Request a thyroid ultrasound scan if nodules or swelling are palpated."
        ],
        "medication": [
          "Levothyroxine (synthetic T4 hormone replacement) for Hypothyroidism.",
          "Anti-thyroid medications (e.g., Methimazole or Propylthiouracil) for Hyperthyroidism.",
          "Selenium and Zinc supplements (under physician guidance) to support T4 to T3 conversion."
        ],
        "nutrition": [
          "Incorporate iodine-rich foods (kelp, seaweeds, organic dairy) only if Hypothyroidism is non-autoimmune.",
          "Ensure sufficient Selenium (2 Brazil nuts daily) and Zinc (pumpkin seeds, lentils) to aid hormone activation.",
          "Avoid excess raw goitrogens (uncooked broccoli, kale, cabbage) which can inhibit iodine uptake.",
          "Adopt a gluten-free diet if diagnosed with Hashimoto's thyroiditis (frequently reduces antibody levels)."
        ],
        "remedies": [
          "Maintain a consistent sleep schedule to support adrenal health, which directly affects thyroid function.",
          "Reduce chronic stress levels (high cortisol inhibits active thyroid hormone production).",
          "Incorporate virgin coconut oil (contains medium-chain fatty acids supporting metabolism)."
        ],
        "exercise": [
          "Engage in regular low-to-moderate cardio (brisk walking, elliptical) to stimulate sluggish metabolism.",
          "Perform strength training to offset muscle loss and joint stiffness associated with thyroid issues.",
          "Avoid over-exercising or excessive cardio, which can overload adrenals and downregulate thyroid conversion."
        ]
      }
    ),
    ScreeningCategory(
      id: "anemia",
      title: "Iron Deficiency Anemia Screener",
      description: "Screen for iron deficiencies caused by blood loss, dietary gaps, or absorption limits.",
      icon: Icons.opacity_rounded,
      questions: [
        "Do you suffer from persistent, extreme fatigue and physical weakness that doesn't improve with rest?",
        "Do you have unusually pale skin, gums, or pale inner eyelids?",
        "Do you experience frequent coldness in your hands and feet compared to normal body temperature?",
        "Do you get short of breath or experience chest flutter/palpitations during minor physical activities?",
        "Do you experience frequent lightheadedness, dizziness, or headaches?",
        "Do you have brittle, spoon-shaped nails or unusual cravings for non-food items like ice, dirt, or paper (pica)?",
        "Do you experience exceptionally heavy menstrual periods (soaking through products in 1-2 hours)?",
      ],
      recommendations: {
        "doctor": [
          "Consult a general physician.",
          "Request a Complete Blood Count (CBC) and full Serum Iron Panel (Serum Iron, Ferritin, TIBC, Transferrin).",
          "Identify the root cause of heavy menstrual bleeding (menorrhagia) via a gynecological consult."
        ],
        "medication": [
          "Oral Iron supplements (such as Ferrous Sulfate, Ferrous Gluconate, or Iron Bisglycinate).",
          "Take iron supplements alongside Vitamin C (500mg) to double absorption rate.",
          "Intravenous (IV) iron infusions if oral iron is not tolerated or absorption is severely impaired."
        ],
        "nutrition": [
          "Increase heme iron sources (red meat, poultry, fish) which are highly bioavailable.",
          "Incorporate non-heme iron sources (spinach, lentils, beans, fortified cereals) paired with citrus fruits.",
          "Avoid drinking coffee, black tea, or milk with meals (tannins, calcium, and polyphenols block iron absorption).",
          "Consume Vitamin C-rich foods (bell peppers, strawberries, tomatoes) to assist iron uptake."
        ],
        "remedies": [
          "Cook in a cast-iron skillet (research shows it naturally transfers small amounts of dietary iron into foods).",
          "Space out calcium supplements and antacids at least 2 hours away from iron-rich meals.",
          "Drink nettle leaf tea (naturally high in iron and vitamin C)."
        ],
        "exercise": [
          "Perform low-intensity activities (stretching, gentle walking) while iron stores are being replenished.",
          "Avoid intense cardiovascular workouts until hemoglobin levels normalize to prevent heart strain.",
          "Listen to your body and rest immediately if you feel dizzy, short of breath, or lightheaded during movement."
        ]
      }
    )
  ];

  ScreeningCategory? _activeCategory;
  int _currentQuestionIndex = 0;
  final List<bool> _answers = [];
  bool _quizCompleted = false;
  String _calculatedRisk = "Low";

  void _startQuiz(ScreeningCategory cat) {
    setState(() {
      _activeCategory = cat;
      _currentQuestionIndex = 0;
      _answers.clear();
      _quizCompleted = false;
    });
  }

  void _submitAnswer(bool yes) {
    _answers.add(yes);
    if (_currentQuestionIndex < _activeCategory!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _calculateResults();
    }
  }

  void _calculateResults() {
    int yesCount = _answers.where((ans) => ans == true).length;
    String risk = "Low";

    if (_activeCategory!.id == "breast_cancer") {
      // Special rules for breast cancer: any positive on symptom questions 2,3,4 or 4+ total positive is High
      bool hasKeySymptoms = _answers[1] || _answers[2] || _answers[3];
      if (hasKeySymptoms || yesCount >= 4) {
        risk = "High";
      } else if (yesCount >= 2) {
        risk = "Moderate";
      } else {
        risk = "Low";
      }
    } else {
      // Standard counting logic
      if (yesCount >= 5) {
        risk = "High";
      } else if (yesCount >= 3) {
        risk = "Moderate";
      } else {
        risk = "Low";
      }
    }

    setState(() {
      _calculatedRisk = risk;
      _quizCompleted = true;
    });
  }

  void _resetScreen() {
    setState(() {
      _activeCategory = null;
      _currentQuestionIndex = 0;
      _answers.clear();
      _quizCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () {
            if (_activeCategory != null) {
              _resetScreen();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _activeCategory == null ? 'Health Screening Hub' : _activeCategory!.title,
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _activeCategory == null
          ? _buildHubView()
          : _quizCompleted
              ? _buildResultsView()
              : _buildQuizView(),
    );
  }

  Widget _buildHubView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Women's Health\nScreening Hub",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary, height: 1.2),
        ),
        const SizedBox(height: 8),
        const Text(
          "Perform clinically-backed symptoms evaluations to assess risk levels and unlock tailored lifestyle recommendations.",
          style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        ..._categories.map((cat) => _buildCategoryCard(cat)),
      ],
    );
  }

  Widget _buildCategoryCard(ScreeningCategory cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startQuiz(cat),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.description,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Text("Start Assessment", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    double progress = (_currentQuestionIndex + 1) / _activeCategory!.questions.length;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Question ${_currentQuestionIndex + 1} of ${_activeCategory!.questions.length}",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                "${(progress * 100).toInt()}% completed",
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
          const SizedBox(height: 48),

          // Question Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Do you experience this symptom?",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Text(
                  _activeCategory!.questions[_currentQuestionIndex],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.4),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submitAnswer(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("NO", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _submitAnswer(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text("YES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_currentQuestionIndex > 0)
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                    _answers.removeLast();
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 14, color: AppColors.textMuted),
                label: const Text("Previous Question", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    Color riskColor;
    if (_calculatedRisk == "High") {
      riskColor = AppColors.emergency;
    } else if (_calculatedRisk == "Moderate") {
      riskColor = Colors.orange;
    } else {
      riskColor = AppColors.success;
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          // Risk Header
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "ASSESSMENT RESULT",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: riskColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "$_calculatedRisk Risk Level",
                        style: TextStyle(color: riskColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _calculatedRisk == "High"
                      ? "Based on your clinical markers, a specialized checkup is strongly suggested."
                      : _calculatedRisk == "Moderate"
                          ? "Moderate indicators found. Follow lifestyle protocols and monitor symptoms."
                          : "Low markers found. Keep practicing healthy maintenance and yearly checkups.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          // Recommendations TabBar
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: "Doctor & Tests", icon: Icon(Icons.local_hospital_outlined, size: 18)),
                Tab(text: "Nutrition / Diet", icon: Icon(Icons.restaurant_outlined, size: 18)),
                Tab(text: "Exercises", icon: Icon(Icons.directions_run_outlined, size: 18)),
                Tab(text: "Home Remedies", icon: Icon(Icons.home_outlined, size: 18)),
                Tab(text: "Medication Guidelines", icon: Icon(Icons.healing_outlined, size: 18)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Content
          Expanded(
            child: TabBarView(
              children: [
                _buildRecommendationList(_activeCategory!.recommendations["doctor"]!),
                _buildRecommendationList(_activeCategory!.recommendations["nutrition"]!),
                _buildRecommendationList(_activeCategory!.recommendations["exercise"]!),
                _buildRecommendationList(_activeCategory!.recommendations["remedies"]!),
                _buildRecommendationList(_activeCategory!.recommendations["medication"]!),
              ],
            ),
          ),

          // Bottom Action
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _startQuiz(_activeCategory!),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Retake Test", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetScreen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Screening Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(List<String> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
