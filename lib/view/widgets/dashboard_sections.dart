import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import 'safe_network_image.dart';

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
        'desc': 'தமிழ்நாட்டு அரசின் - 1975ஆம் ஆண்டு தமிழ்நாடு சங்கங்கள் பதிவுச்சட்டத்தின் கீழ் (சட்டம் 27/1975) பதிவு செய்யப்பட்டது.'
      },
      {
        'name': 'MSME (மத்திய அரசு)',
        'reg': 'UDYAM-TN-14-0037173',
        'desc': 'மத்திய அரசின் MSME அமைச்சகத்தின் தேசிய தொழில் வகைப்பாட்டு திட்டத்தின் கீழ் (கல்வி ஆதரவு சேவைகள்) பதிவு.'
      },
      {
        'name': 'AICTE (மத்திய அரசு)',
        'reg': 'CORPORATE63C3E52AAD72',
        'desc': 'அகில இந்திய தொழில்நுட்பக் கல்வி சபையின் (AICTE) அதிகாரபூர்வ பயிற்சி வழங்குநர் (Internship Provider) பதிவு.'
      },
      {
        'name': 'மதுரை உலக தமிழ்ச் சங்கம்',
        'reg': 'UTS / TN 126',
        'desc': 'மதுரை உலக தமிழ்ச் சங்கத்தின் அதிகாரபூர்வ உறுப்பினர் (உறுப்பினர் எண்: UTS / TN 126).'
      },
      {
        'name': 'NCS (தொழில் சேவை)',
        'reg': 'S17L69-1517358106310',
        'desc': 'மத்திய அரசின் தொழிலாளர் மற்றும் வேலைவாய்ப்பு அமைச்சகத்தின் தேசிய தொழில் சேவை திட்டத்தின் கீழ் பதிவு.'
      },
      {
        'name': 'NITI Aayog (மத்திய அரசு)',
        'reg': 'TN/2021/0282436',
        'desc': 'மத்திய அரசின் நிதி ஆயோக் திட்டத்தின் கீழ் இயங்கி வரும் அரசு சாரா அமைப்புகளின் கண்ணாடி (NGO Darpan) பதிவு.'
      },
      {
        'name': 'ISBN (RRRNA)',
        'reg': 'RRRNA for ISBN',
        'desc': 'ராஜா ராம்மோஹன் ராய் தேசிய புத்தக வெளியீட்டு நிறுவனம் மூலம் புத்தகம் வெளியிடுதல் திட்டத்தில் பதிவு.'
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
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recognitions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = recognitions[index];
              return Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
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
        'title': 'வாகை பனுவல் மன்றம்',
        'desc': 'இலக்கிய வாசிப்பு மற்றும் கலந்துரையாடல் மூலம் அறிவை மேம்படுத்துதல்.',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFF2196F3),
        'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?q=80&w=500&auto=format&fit=crop',
      },
      {
        'title': 'வாகை மழலையர் மன்றம்',
        'desc': 'குழந்தைகளின் தமிழ்த்திறன் வளர்ச்சி மற்றும் நீதிக்கதைகள் வாயிலாக அறம் வளர்த்தல்.',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFFE91E63),
        'image': 'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?q=80&w=500&auto=format&fit=crop',
      },
      {
        'title': 'வாகை மகளிர் மன்றம்',
        'desc': 'பெண்களின் தனித்திறனை வெளிக்கொணரவும், சமூகத்தில் அவர்களின் பங்களிப்பை ஊக்குவிக்கவும்.',
        'icon': Icons.woman_rounded,
        'color': const Color(0xFF9C27B0),
        'image': 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?q=80&w=500&auto=format&fit=crop',
      },
      {
        'title': 'வாகை குறள் மன்றம்',
        'desc': 'திருக்குறள் நெறிமுறைகளை வாழ்வியலோடு இணைத்து அறம் சார்ந்த சமூகம் படைத்தல்.',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFFFF5722),
        'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?q=80&w=500&auto=format&fit=crop',
      },
      {
        'title': 'வாகை மாணாக்கர் மன்றம்',
        'desc': 'மாணவர்களின் பன்முகத் திறன்களை வளர்த்தெடுத்து வருங்காலத் தலைவர்களாக உருவாக்குதல்.',
        'icon': Icons.school_rounded,
        'color': const Color(0xFF4CAF50),
        'image': 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=500&auto=format&fit=crop',
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
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: forums.length,
          itemBuilder: (context, index) {
            final forum = forums[index];
            return _MandramCard(forum: forum);
          },
        ),
      ],
    );
  }
}

class _MandramCard extends StatelessWidget {
  final Map<String, dynamic> forum;

  const _MandramCard({required this.forum});

  @override
  Widget build(BuildContext context) {
    final color = forum['color'] as Color;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                    ),
                    child: SafeNetworkImage(
                      imageUrl: forum['image'] as String,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: Text(
                      forum['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forum['desc'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'மேலும் அறிய',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialMediaSection extends StatelessWidget {
  const SocialMediaSection({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialPlatforms = [
      {
        'name': 'Facebook',
        'icon': Icons.facebook_rounded,
        'color': const Color(0xFF1877F2),
        'url': 'https://www.facebook.com/share/1Cq47zBFS3/?mibextid=wwXIfr'
      },
      {
        'name': 'Instagram',
        'icon': Icons.camera_alt_rounded,
        'color': const Color(0xFFE4405F),
        'url': 'https://www.instagram.com/vaagaitamilsangam?igsh=MWI3MjRvMnpmcDJ1Yw%3D%3D&utm_source=qr'
      },
      {
        'name': 'LinkedIn',
        'icon': Icons.business_rounded,
        'color': const Color(0xFF0A66C2),
        'url': 'https://www.linkedin.com/company/%E0%AE%B5%E0%AE%BE%E0%AE%95%E0%AF%88-%E0%AE%A4%E0%AE%AE%E0%AE%BF%E0%AE%B4%E0%AF%8D%E0%AE%9A%E0%AF%8D%E0%AE%9A%E0%AE%99%E0%AF%8D%E0%AE%95%E0%AE%AE%E0%AF%8D/'
      },
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_rounded,
        'color': const Color(0xFF25D366),
        'url': 'https://whatsapp.com/channel/0029Vb7qrzV30LKUarhSNJ0j'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'சமூக வலைதளங்கள் (Follow Us)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
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
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            runSpacing: 20,
            spacing: 20,
            children: socialPlatforms.map((platform) => _buildSocialIcon(
              platform['name'] as String,
              platform['icon'] as IconData,
              platform['color'] as Color,
              platform['url'] as String,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String name, IconData icon, Color color, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
