import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'வாகை தமிழ்ச்சங்கம் - அறிமுகம்',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'தமிழன்னையின் மணிமகுடத்தில் மற்றுமொரு மாணிக்கமாய் மிளிர்கிறது நமது வாகை தமிழ்ச்சங்கம். தமிழக அரசு அனுமதி பெற்று, தமிழ் மொழி, இலக்கியம், பண்பாடு ஆகியவை சார்ந்த அறிவை இக்கால அறிவியல் சிந்தனை & திறன்களுடன் அனைத்து தரப்பினரிடமும் ஊக்குவித்தலையும் வளர்த்தலையும் மேம்படுத்துதலையும் நோக்கமாகக்கொண்டு வாகை தமிழ்ச்சங்கம் இயங்கி வருகிறது.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'நமது வாகை தமிழ்ச்சங்கம், தமிழ்நாடு அரசு மற்றும் இந்திய அரசின் மேலும் பல செயல்திட்டங்களின் கீழும் அனுமதி பெற்ற தன்னார்வலர், தமிழ்சார்ந்த சமூக சேவை நோக்கம் கொண்ட அமைப்பாகும். மதுரை உலக தமிழ்ச் சங்கத்தின் அதிகாரபூர்வ உறுப்பினராக இணைந்து மட்டுமின்றி, உள்நாட்டு & பன்னாட்டு அளவிலான பலதரப்பட்ட மக்கள் வயது வேறுபாடின்றி நமது வாகை தமிழ்ச்சங்கத்தில் இணைந்து தத்தமது திறன்களை மேம்படுத்தவும் வெளிக்கொணரவுமான களமாகத் திகழ்ந்து வருகிறது.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                ),
                child: const Center(
                  child: Text(
                    'மா',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'மா. மனோஜ்குமார்',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'தலைவர்',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'வாகை தமிழ்ச்சங்கம், நாமக்கல்',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VisionMissionSection extends StatelessWidget {
  const VisionMissionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCard(
          context,
          title: 'நோக்கு (Vision)',
          content: 'தமிழ் மொழி, இலக்கியம், பண்பாடு ஆகியவை சார்ந்த அறிவை இக்கால அறிவியல் சிந்தனை & திறன்களுடன் அனைத்து தரப்பினரிடமும் ஊக்குவித்தலும், வளர்த்தலும், மேம்படுத்துதலும்.',
          icon: Icons.visibility_rounded,
          color: const Color(0xFF1B5E20),
        ),
        const SizedBox(height: 16),
        _buildCard(
          context,
          title: 'போக்கு (Mission)',
          isList: true,
          points: [
            'கற்றல், கற்பித்தல், எழுதுதல், வாசித்தல் போன்ற திறன்களுக்குப் பயிற்சியளித்தலும், வெளிப்படுத்துதலும் மேம்படுத்துதலும் செய்தல்.',
            'கருத்தரங்குகள், வினாடி வினாக்கள், ஆசிரிய-மாணவ மேம்பாட்டுத் திட்டங்கள், ஆய்வரங்கங்கள் ஆகிய நிகழ்வுகள் மூலம் தமிழ் வளர்ச்சிப் பணிகளில் ஈடுபடுதல்.',
            'தலைசிறந்த தமிழ் ஆளுமைகள், சிறந்த கலைஞர்கள், துறைசார், திறன்சார்ந்த வல்லுநர்கள், அறிஞர்கள், ஆய்வாளர்கள், தன்னார்வலர்கள் ஆகியோருக்குப் பட்டங்களும் விருதுகளும் வழங்கிப் பெருமைப்படுத்துதல்.',
          ],
          icon: Icons.track_changes_rounded,
          color: const Color(0xFFD4AF37),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title,
    String? content,
    bool isList = false,
    List<String>? points,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.05), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isList)
            Text(
              content!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            )
          else
            ...points!.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}

class ApprovalsSection extends StatelessWidget {
  const ApprovalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final recognitions = [
      {
        'name': 'தமிழ்நாடு அரசு',
        'reg': 'SRG/நாமக்கல்/143/2022',
        'desc': '1975ஆம் ஆண்டு தமிழ்நாடு சங்கங்கள் பதிவுச்சட்டத்தின் கீழ் பதிவு செய்யப்பட்டது.'
      },
      {
        'name': 'MSME',
        'reg': 'UDYAM-TN-14-0037173',
        'desc': 'மத்திய அரசின் நுண்ணிய, சிறு மற்றும் நடுத்தர நிறுவன அமைச்சகத்தின் கீழ் பதிவு செய்யப்பட்டது.'
      },
      {
        'name': 'AICTE',
        'reg': 'CORPORATE63C3E52AAD72',
        'desc': 'அகில இந்திய தொழில்நுட்பக் கல்வி சபையின் (AICTE) பயிற்சி வழங்குநர் பதிவு.'
      }
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'அங்கீகாரங்களும் அனுமதிகளும்',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recognitions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = recognitions[index];
              return Container(
                width: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                item['reg']!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['desc']!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ForumSection extends StatelessWidget {
  const ForumSection({super.key});

  @override
  Widget build(BuildContext context) {
    final forums = [
      {
        'title': 'மழலையர் மன்றம்',
        'desc': 'குழந்தைகள் அறிய வேண்டிய நீதிக்கதைகள் மற்றும் கதை ஞாயிறு நிகழ்வுகள்.',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFFE91E63),
      },
      {
        'title': 'மகளிர் மன்றம்',
        'desc': 'பெண்களின் தனித்திறனை வெளிக்கொணரும் பொருட்டும், தமிழ்த்திறனை மேம்படுத்தவும்.',
        'icon': Icons.woman_rounded,
        'color': const Color(0xFF9C27B0),
      },
      {
        'title': 'பனுவல் மன்றம்',
        'desc': 'புத்தகம் வாசிக்கும் பழக்கத்தை ஏற்படுத்தவும், இலக்கியங்களை எளிய முறையில் அறிமுகப்படுத்தவும்.',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF2196F3),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'மன்றம் (Forum / Community)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Announcement Card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                   SizedBox(width: 10),
                   Text(
                    'அறிவிப்பு',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'புதிய இலக்கியப் போட்டி அடுத்த மாதம் தொடங்க உள்ளது. ஆர்வமுள்ள மாணவர்கள் தயார் நிலையில் இருக்கவும்!',
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        ...forums.map((forum) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (forum['color'] as Color).withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: (forum['color'] as Color).withOpacity(0.1),
                child: Icon(forum['icon'] as IconData, color: forum['color'] as Color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forum['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: forum['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      forum['desc'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
            ],
          ),
        )),
      ],
    );
  }
}
