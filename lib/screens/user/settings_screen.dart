import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/models/statistics_model.dart';
import 'package:kronk/riverpod/general/navbar_provider.dart';
import 'package:kronk/riverpod/general/theme_notifier_provider.dart';
import 'package:kronk/riverpod/settings/settings_statistics.dart';
import 'package:kronk/utility/dimensions.dart';
import 'package:kronk/utility/extensions.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:kronk/utility/url_launches.dart';
import 'package:kronk/widgets/profile/custom_painters.dart';
import 'package:kronk/widgets/settings/custom_toggle.dart';
import 'package:kronk/widgets/settings/stats_bar_chart.dart';
import 'package:rive/rive.dart' hide LinearGradient;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);

    final double margin2 = dimensions.margin2;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(leading: BackButtonWidget(), title: Text('Settings'), floating: true, snap: true),
          const SectionTitleWidget(title: 'appearance'),
          const AppearanceSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: margin2)),
          const SectionTitleWidget(title: 'service'),
          const ServiceSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: margin2)),
          const SectionTitleWidget(title: 'statistics'),
          const StatisticsSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: margin2)),
          const SectionTitleWidget(title: 'support'),
          const SupportSectionWidget(),
          const MaraudersMapFootprints(),
          const DisappointingSectionWidget(),
          SliverToBoxAdapter(child: SizedBox(height: margin2)),
        ],
      ),
    );
  }
}

class SectionTitleWidget extends StatelessWidget {
  final String title;

  const SectionTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final Dimensions dimensions = Dimensions.of(context);

    final double margin2 = dimensions.margin2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: margin2),
      sliver: SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: Text(title, style: Theme.of(context).textTheme.displaySmall),
        ),
      ),
    );
  }
}

class AppearanceSectionWidget extends ConsumerWidget {
  const AppearanceSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Dimensions dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final List<Themes> allThemes = themeNotifier.getThemes();

    final double contentWidth1 = dimensions.with1;
    final double margin2 = dimensions.margin2;
    final double margin3 = dimensions.margin3;
    final double padding3 = dimensions.padding3;
    final double padding4 = dimensions.padding4;
    final double height1 = dimensions.height1;
    final double themeCircleRadius = dimensions.themeCircleRadius;
    return SliverToBoxAdapter(
      child: SizedBox(
        width: contentWidth1,
        height: height1,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.transparent, Colors.black, Colors.black, Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, 0.05, 0.1, 0.9, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.separated(
            padding: EdgeInsetsGeometry.symmetric(horizontal: margin2),
            scrollDirection: Axis.horizontal,
            itemCount: allThemes.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async => await themeNotifier.changeTheme(theme: allThemes.elementAt(index)),
                child: Container(
                  padding: EdgeInsets.only(top: padding4, left: padding3, right: padding3),
                  decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    spacing: padding4,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryText, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: CustomPaint(
                          size: Size(themeCircleRadius, themeCircleRadius),
                          painter: HalfCirclePainter(
                            firstColor: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryBackground,
                            secondColor: MyTheme.fromThemes(theme: allThemes.elementAt(index)).secondaryBackground,
                          ),
                        ),
                      ),
                      Text(
                        allThemes.elementAt(index).name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MyTheme.fromThemes(theme: allThemes.elementAt(index)).primaryText),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => SizedBox(width: margin3),
          ),
        ),
      ),
    );
  }
}

class ServiceSectionWidget extends ConsumerWidget {
  const ServiceSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final List<NavbarModel> services = ref.watch(navbarProvider);

    final double iconSize3 = dimensions.iconSize3;
    final double padding2 = dimensions.padding2;
    final double padding3 = dimensions.padding3;
    final double padding4 = dimensions.padding4;
    final double margin2 = dimensions.margin2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: margin2),
      sliver: SliverReorderableList(
        itemCount: services.length,
        onReorder: (int oldIndex, int newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          await ref.read(navbarProvider.notifier).reorderNavbarItem(oldIndex: oldIndex, newIndex: newIndex);
        },
        itemBuilder: (context, index) {
          final service = services.elementAt(index);
          final bool isAvailable = !service.isPending;
          return ReorderableDelayedDragStartListener(
            key: ValueKey(service.route),
            index: index,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: padding3, horizontal: padding3),
              margin: EdgeInsets.symmetric(vertical: padding4),
              decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: padding2,
                    children: [
                      Icon(Icons.drag_indicator_rounded, size: iconSize3, color: service.isEnabled ? theme.primaryText : theme.secondaryText),
                      Text(
                        service.route.replaceFirst('/', '').toTitleCaseWithSpaces(),
                        style: service.isEnabled ? Theme.of(context).textTheme.bodyMedium : Theme.of(context).textTheme.bodyMedium?.copyWith(color: theme.secondaryText),
                      ),
                    ],
                  ),
                  Row(
                    spacing: padding2,
                    children: [
                      if (service.isUpcoming)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: padding3, vertical: padding4),
                          decoration: BoxDecoration(color: theme.tertiaryBackground, borderRadius: BorderRadius.circular(padding2)),
                          child: Text('Upcoming', style: Theme.of(context).textTheme.headlineSmall),
                        ),
                      if (service.isPending)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: padding3, vertical: padding4),
                          decoration: BoxDecoration(color: theme.tertiaryBackground, borderRadius: BorderRadius.circular(padding2)),
                          child: Text('Future', style: Theme.of(context).textTheme.headlineSmall),
                        ),
                      CustomToggle(index: index, isEnabled: service.isEnabled, toggleable: isAvailable),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatisticsSectionWidget extends ConsumerWidget {
  const StatisticsSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    AsyncValue<StatisticsModel> statistics = ref.watch(settingsStatisticsWsStreamProvider);

    final double margin2 = dimensions.margin2;
    final double radius4 = dimensions.radius4;
    final double padding2 = dimensions.padding2;
    final double height2 = dimensions.height2;
    final List<String> statNames = ['weekly', 'monthly', 'yearly'];
    return statistics.when(
      data: (StatisticsModel data) {
        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: margin2),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(padding2)),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  spacing: padding2,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: padding2, top: padding2, right: padding2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total users: ${data.total}', style: Theme.of(context).textTheme.labelLarge),
                          SizedBox(width: height2 * 1.16, height: height2, child: const RiveAnimation.asset('assets/animations/heart.riv')),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding2),
                      child: Container(
                        decoration: BoxDecoration(color: theme.primaryBackground, borderRadius: BorderRadius.circular(radius4)),
                        child: TabBar(
                          padding: const EdgeInsets.all(2),
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(color: theme.secondaryBackground, borderRadius: BorderRadius.circular(radius4 - 2)),
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                          unselectedLabelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.secondaryText),
                          indicatorAnimation: TabIndicatorAnimation.elastic,
                          tabs: List.generate(3, (index) => Tab(height: 24, text: statNames.elementAt(index))),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 240,
                      child: TabBarView(
                        children: [
                          StatsBarChart(stats: data.weekly),
                          StatsBarChart(stats: data.monthly),
                          StatsBarChart(stats: data.yearly),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        myLogger.d('### error, error: $error, stackTrace: $stackTrace');
        return const SliverToBoxAdapter(child: SizedBox(height: 200, width: 200, child: RiveAnimation.asset('assets/animations/error_glitch.riv')));
      },
      loading: () {
        myLogger.d('### loading...');
        return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class SupportSectionWidget extends ConsumerWidget {
  const SupportSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final double contentWidth1 = dimensions.with1;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double cornerRadius1 = dimensions.radius1;
    final double textSize3 = dimensions.textSize3;
    final double padding3 = dimensions.padding3;
    final double margin2 = dimensions.margin2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: margin2),
      sliver: SliverToBoxAdapter(
        child: Column(
          spacing: padding3,
          children: [
            ElevatedButton(
              onPressed: () async {
                await customURLLauncher(isWebsite: true, url: 'https://buymeacoffee.com/kamronbek');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFFDD00),
                fixedSize: Size(contentWidth1, buttonHeight1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius1)),
              ),
              child: SvgPicture.asset('assets/icons/others/bmc-button.svg'),
            ),
            ElevatedButton(
              onPressed: () async {
                await customURLLauncher(isWebsite: true, url: 'https://tirikchilik.uz/kamronbek');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: Size(contentWidth1, buttonHeight1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius1)),
              ),
              child: SvgPicture.asset('assets/icons/others/tirikchilik.svg', height: textSize3),
            ),
          ],
        ),
      ),
    );
  }
}

class DisappointingSectionWidget extends ConsumerWidget {
  const DisappointingSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final dimensions = Dimensions.of(context);

    final double contentWidth1 = dimensions.with1;
    final double buttonHeight1 = dimensions.buttonHeight1;
    final double cornerRadius1 = dimensions.radius1;
    final double padding3 = dimensions.padding3;
    final double margin2 = dimensions.margin3;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: margin2),
      sliver: SliverToBoxAdapter(
        child: Column(
          spacing: padding3,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                fixedSize: Size(contentWidth1, buttonHeight1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius1)),
              ),
              child: Text('Log out', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: theme.primaryBackground)),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                fixedSize: Size(contentWidth1, buttonHeight1),
                side: const BorderSide(color: Colors.redAccent, width: 2.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cornerRadius1)),
              ),
              child: Text('Delete account', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }
}

class MaraudersMapFootprints extends ConsumerWidget {
  const MaraudersMapFootprints({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider);
    return SliverToBoxAdapter(
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.transparent, theme.secondaryText, theme.primaryText, Colors.redAccent, Colors.redAccent.withAlpha(128), Colors.redAccent.withAlpha(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds),
        blendMode: BlendMode.srcIn,
        child: SvgPicture.asset('assets/icons/others/footprints.svg'),
      ),
    );
  }
}

class BackButtonWidget extends ConsumerWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dimensions = Dimensions.of(context);
    final MyTheme theme = ref.watch(themeNotifierProvider);
    final bool isAnyServiceEnabled = ref.watch(navbarProvider).any((service) => service.isEnabled);

    final double iconSize1 = dimensions.iconSize1;
    return IconButton(
      onPressed: () {
        myLogger.i('isAnyServiceEnabled: $isAnyServiceEnabled');
        if (!isAnyServiceEnabled) {
          context.go('/welcome');
        } else {
          final Storage storage = Storage();
          storage.setSettingsAll({'isDoneSettings': true});
          String firstRoute = storage.getRoute();
          context.go(firstRoute);
        }
      },
      icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText, size: iconSize1),
    );
  }
}
