import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class LegalSection {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const LegalSection({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });
}

class LegalDocument {
  final String slug;
  final String title;
  final String summary;
  final List<LegalSection> sections;
  final String? version;
  final String? body;

  const LegalDocument({
    required this.slug,
    required this.title,
    required this.summary,
    required this.sections,
    this.version,
    this.body,
  });

  bool get hasStructuredSections => sections.isNotEmpty;
}

/// Same legal content as warom_public Terms & Privacy pages.
abstract final class WaromLegal {
  static const terms = LegalDocument(
    slug: 'terms-and-conditions',
    title: 'Terms & Conditions',
    summary:
        'The rules for using WAROM — including accounts, acceptable use, monetization, and community safety.',
    sections: [
      LegalSection(
        title: 'Agreement to these terms',
        paragraphs: [
          'By accessing WAROM’s public website or using WAROM services, you agree to these Terms and Conditions. If you do not agree, do not use the platform. These terms apply to users, chatters, visitors, and anyone submitting inquiries through the site.',
        ],
      ),
      LegalSection(
        title: 'Eligibility',
        paragraphs: [
          'You must be at least 18 years old and legally able to enter a binding agreement. You are responsible for ensuring that your use of WAROM complies with local laws in your country or region.',
        ],
      ),
      LegalSection(
        title: 'Accounts and profiles',
        paragraphs: [
          'You agree to provide accurate account information and keep your credentials secure. You are responsible for activity under your account. WAROM may suspend or terminate accounts that are inaccurate, abusive, fraudulent, or otherwise violate these terms.',
        ],
      ),
      LegalSection(
        title: 'Acceptable use',
        paragraphs: [
          'You agree to use WAROM respectfully and lawfully.',
        ],
        bullets: [
          'Do not harass, threaten, exploit, or deceive other people.',
          'Do not upload illegal, harmful, or non-consensual content.',
          'Do not attempt to bypass security, scrape data, or disrupt services.',
          'Do not use WAROM for money laundering, scams, or unauthorized commercial spam.',
          'Do not impersonate another person or misrepresent your identity in a harmful way.',
        ],
      ),
      LegalSection(
        title: 'Coins, gifts, VIP, and earnings',
        paragraphs: [
          'WAROM may offer virtual coins, gifts, VIP plans, and chatter earnings. Coin balances, gift values, VIP benefits, and earnings splits are configured by the platform and may change. Virtual items generally have no cash value outside WAROM unless a withdrawal feature expressly applies to eligible chatter earnings. Chargebacks, fraud, or policy breaches may result in adjusted balances, withheld payouts, or account action.',
        ],
      ),
      LegalSection(
        title: 'Content and media',
        paragraphs: [
          'You retain rights to content you create, but grant WAROM a license to host, display, moderate, and distribute that content as needed to operate the service. WAROM may remove content that violates policy, law, or community safety standards.',
        ],
      ),
      LegalSection(
        title: 'Moderation and enforcement',
        paragraphs: [
          'We may investigate reports, review uploads, and take action including warnings, content removal, feature limits, suspension, or termination. Chatter accounts may face a higher verification and compliance standard because payouts are involved.',
        ],
      ),
      LegalSection(
        title: 'Disclaimers and limitation of liability',
        paragraphs: [
          'WAROM is provided on an “as available” basis. We do not guarantee uninterrupted service, perfect matching outcomes, or that every profile interaction will be positive. To the fullest extent allowed by law, WAROM is not liable for indirect, incidental, or consequential damages arising from use of the platform.',
        ],
      ),
      LegalSection(
        title: 'Changes to these terms',
        paragraphs: [
          'We may update these Terms and Conditions from time to time. Continued use after updates means you accept the revised terms. The “Last updated” date on this page shows the latest revision.',
        ],
      ),
      LegalSection(
        title: 'Contact',
        paragraphs: [
          'Questions about these terms can be sent through Talk to us or email hello@warom.app.',
        ],
      ),
    ],
  );

  static const privacy = LegalDocument(
    slug: 'privacy-policy',
    title: 'Privacy Policy',
    summary:
        'How WAROM collects, uses, and protects your information across discovery, chat, calls, gifts, and inquiries.',
    sections: [
      LegalSection(
        title: 'Who we are',
        paragraphs: [
          'WAROM is a dual-sided social connection platform where users discover people, chat, call, and exchange gifts, while chatters earn through eligible interactions. This Privacy Policy explains how we collect, use, store, and protect personal information when you visit warom_public or use WAROM services.',
        ],
      ),
      LegalSection(
        title: 'Information we collect',
        paragraphs: [
          'We collect information you provide directly and information generated when you use the platform.',
        ],
        bullets: [
          'Account details such as name, username, email, phone number, date of birth, gender, country, city, bio, and profile media.',
          'Inquiry details when you contact us through Talk to us, including name, email, subject, and message.',
          'Usage data such as device type, browser, approximate location, pages visited, and interaction logs needed for security and product improvement.',
          'Transaction-related records for coin purchases, gifts, VIP subscriptions, withdrawals, and related ledger activity where applicable.',
        ],
      ),
      LegalSection(
        title: 'How we use your information',
        paragraphs: [
          'We use personal information only for legitimate platform operations and communication.',
        ],
        bullets: [
          'To create and manage accounts, profiles, and verification status.',
          'To enable discovery, messaging, calls, gifts, VIP features, and earnings flows.',
          'To respond to inquiries, partnership requests, and support messages.',
          'To detect fraud, enforce policies, moderate content, and protect users and chatters.',
          'To improve product performance, safety systems, and customer experience.',
        ],
      ),
      LegalSection(
        title: 'When we share information',
        paragraphs: [
          'We do not sell personal information. We may share limited data with trusted processors only when needed to operate WAROM, such as payment providers, cloud hosting, analytics, verification partners, or legal authorities when required by law.',
        ],
      ),
      LegalSection(
        title: 'Retention and security',
        paragraphs: [
          'We keep information only as long as needed for the purposes described in this policy, including legal, accounting, safety, and dispute-resolution needs. We apply technical and organizational safeguards, including access controls and secure transmission where appropriate. No system is perfectly secure, so we continuously improve our protections.',
        ],
      ),
      LegalSection(
        title: 'Your choices and rights',
        paragraphs: [
          'Depending on your location, you may request access, correction, deletion, or restriction of certain personal data. You may also update profile details in-app where available, or contact us to exercise privacy rights. Some records may be retained where required for safety, fraud prevention, or legal compliance.',
        ],
      ),
      LegalSection(
        title: 'Age restriction',
        paragraphs: [
          'WAROM is intended for adults. You must be at least 18 years old to create an account or use monetized features. We do not knowingly collect personal information from children under 18.',
        ],
      ),
      LegalSection(
        title: 'Contact',
        paragraphs: [
          'For privacy questions or requests, use Talk to us on the website or email hello@warom.app. We will review and respond as promptly as reasonably possible.',
        ],
      ),
    ],
  );

  static LegalDocument fallbackForSlug(String slug) {
    if (slug == privacy.slug) return privacy;
    return terms;
  }

  /// Loads a published policy from the public API when available; otherwise uses portal copy.
  static Future<LegalDocument> load(String slug) async {
    final fallback = fallbackForSlug(slug);
    try {
      final response = await http
          .get(
            Uri.parse('$kWaromApiBase/api/public/policies/$slug'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 400) return fallback;
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (payload['success'] == false) return fallback;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) return fallback;
      final title = '${data['title'] ?? fallback.title}';
      final body = '${data['body'] ?? ''}'.trim();
      final version = data['version']?.toString();
      if (body.isEmpty) {
        return LegalDocument(
          slug: slug,
          title: title,
          summary: fallback.summary,
          sections: fallback.sections,
          version: version,
        );
      }
      return LegalDocument(
        slug: slug,
        title: title,
        summary: fallback.summary,
        sections: const [],
        version: version,
        body: body,
      );
    } catch (_) {
      return fallback;
    }
  }
}
