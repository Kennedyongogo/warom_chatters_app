import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../legal/warom_legal.dart';
import '../../theme.dart';

class PolicyPage extends StatefulWidget {
  final String slug;

  const PolicyPage({super.key, required this.slug});

  static Future<void> open(BuildContext context, String slug) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PolicyPage(slug: slug)),
    );
  }

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  late Future<LegalDocument> _future;
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _future = WaromLegal.load(widget.slug);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isPrivacy => widget.slug == WaromLegal.privacy.slug;

  IconData get _heroIcon =>
      _isPrivacy ? Icons.privacy_tip_rounded : Icons.gavel_rounded;

  String get _eyebrow => _isPrivacy ? 'Privacy' : 'Legal';

  GlobalKey _keyFor(int index) =>
      _sectionKeys.putIfAbsent(index, GlobalKey.new);

  Future<void> _jumpTo(int index) async {
    final ctx = _keyFor(index).currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = WaromLegal.fallbackForSlug(widget.slug);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: MtaaniColors.canvas,
        body: FutureBuilder<LegalDocument>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _LoadingState(title: fallback.title, icon: _heroIcon);
            }

            final doc = snapshot.data!;
            final sections = doc.hasStructuredSections
                ? doc.sections
                : _sectionsFromBody(doc);

            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  backgroundColor: MtaaniColors.canvas,
                  foregroundColor: MtaaniColors.ink,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: MtaaniColors.ink,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _HeroCard(
                      eyebrow: _eyebrow,
                      title: doc.title,
                      summary: doc.summary,
                      version: doc.version,
                      icon: _heroIcon,
                    ),
                  ),
                ),
                if (sections.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                      child: _SectionChips(
                        titles: sections.map((s) => s.title).toList(),
                        onTap: _jumpTo,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final section = sections[index];
                        return Padding(
                          key: _keyFor(index),
                          padding: EdgeInsets.only(
                            bottom: index == sections.length - 1 ? 0 : 12,
                          ),
                          child: _SectionCard(
                            index: index + 1,
                            section: section,
                          ),
                        );
                      },
                      childCount: sections.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      48 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    child: const Text(
                      'Questions? Reach us via Talk to us or hello@warom.app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: MtaaniColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<LegalSection> _sectionsFromBody(LegalDocument doc) {
    final body = (doc.body ?? '').trim();
    if (body.isEmpty) return doc.sections;
    final chunks = body
        .split(RegExp(r'\n{2,}'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (chunks.isEmpty) {
      return [LegalSection(title: doc.title, paragraphs: [body])];
    }
    return [
      for (var i = 0; i < chunks.length; i++)
        LegalSection(
          title: i == 0 ? 'Overview' : 'Section ${i + 1}',
          paragraphs: [chunks[i]],
        ),
    ];
  }
}

class _LoadingState extends StatelessWidget {
  final String title;
  final IconData icon;

  const _LoadingState({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: MtaaniColors.canvas,
          foregroundColor: MtaaniColors.ink,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: MtaaniColors.blush,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: MtaaniColors.coralDeep, size: 30),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: MtaaniColors.coralDeep,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loading document…',
                style: TextStyle(color: MtaaniColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String summary;
  final String? version;
  final IconData icon;

  const _HeroCard({
    required this.eyebrow,
    required this.title,
    required this.summary,
    required this.version,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B75),
            MtaaniColors.coralDeep,
            Color(0xFFD92D4A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MtaaniColors.coralDeep.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 28,
            bottom: -36,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        version != null && version!.isNotEmpty
                            ? 'v$version'
                            : 'WAROM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionChips extends StatelessWidget {
  final List<String> titles;
  final ValueChanged<int> onTap;

  const _SectionChips({required this.titles, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ON THIS PAGE',
          style: TextStyle(
            fontSize: 11.5,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: MtaaniColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: titles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                child: InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => onTap(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: MtaaniColors.line),
                    ),
                    child: Text(
                      titles[index],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MtaaniColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final int index;
  final LegalSection section;

  const _SectionCard({required this.index, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MtaaniColors.line),
        boxShadow: [
          BoxShadow(
            color: MtaaniColors.ink.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MtaaniColors.blush,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$index'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: MtaaniColors.coralDeep,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: MtaaniColors.ink,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (section.paragraphs.isNotEmpty || section.bullets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: MtaaniColors.line.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 12),
          ],
          for (final paragraph in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                paragraph,
                style: const TextStyle(
                  fontSize: 14.8,
                  height: 1.58,
                  color: MtaaniColors.ink,
                ),
              ),
            ),
          if (section.bullets.isNotEmpty)
            ...section.bullets.map(
              (bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: MtaaniColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(
                          fontSize: 14.6,
                          height: 1.5,
                          color: MtaaniColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
