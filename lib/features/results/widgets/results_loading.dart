import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'filter_chips_bar.dart';

/// Случайные факты на экране загрузки выдачи.
const loadingFacts = [
  'Самый долгий полёт курицы продолжался 13 секунд',
  'Венеция стоит на 118 островах',
  'Летом Эйфелева башня становится выше на 15 сантиметров: металл расширяется от тепла',
  'В Японии больше шести тысяч островов',
  'В Байкале хранится около пятой части мировых запасов пресной воды',
  'В Исландии нет комаров',
  'Самый короткий регулярный авиарейс длится около минуты: между островами Уэстрей и Папа-Уэстрей в Шотландии',
  'Ла-Пас, резиденция правительства Боливии, лежит на высоте около 3 600 метров',
];

String randomLoadingFact() =>
    loadingFacts[math.Random().nextInt(loadingFacts.length)];

/// Серые заготовки чипов под шапкой, пока выдача грузится, и бегущая линия.
class LoadingChipsBar extends StatelessWidget {
  const LoadingChipsBar({super.key});

  static const _widths = [46.0, 144.0, 90.0, 46.0, 110.0, 110.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FilterChipsBar.height,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            // Список без прокрутки: лишние заготовки просто уходят за край.
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                for (final w in _widths)
                  Container(
                    width: w,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
              ],
            ),
          ),
          const Positioned(left: 0, right: 0, bottom: 0, child: _SlidingLine()),
        ],
      ),
    );
  }
}

/// Жёлтый отрезок, который бежит слева направо по кругу.
class _SlidingLine extends StatefulWidget {
  const _SlidingLine();

  @override
  State<_SlidingLine> createState() => _SlidingLineState();
}

class _SlidingLineState extends State<_SlidingLine>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('loading_line'),
      height: 3,
      child: LayoutBuilder(
        builder: (context, box) {
          final segment = box.maxWidth * .45;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_controller.value);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -segment + (box.maxWidth + segment) * t,
                    width: segment,
                    top: 0,
                    bottom: 0,
                    child: const ColoredBox(color: AppColors.accent),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Тело экрана загрузки: вращающаяся планета и случайный факт.
class ResultsLoading extends StatelessWidget {
  const ResultsLoading({super.key, required this.fact});

  final String fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('results_loading'),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Globe(size: 130),
          const SizedBox(height: 56),
          Text(
            fact,
            key: const Key('loading_fact'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Планета: фиолетовый круг, по которому плывут жёлтые материки.
class Globe extends StatefulWidget {
  const Globe({super.key, required this.size});

  final double size;

  @override
  State<Globe> createState() => _GlobeState();
}

class _GlobeState extends State<Globe> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const Key('loading_globe'),
      size: Size.square(widget.size),
      painter: _GlobePainter(_controller),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  /// Контуры материков в долях ленты, которая в два раза шире планеты.
  static const _continents = [
    [
      Offset(.05, .25),
      Offset(.18, .15),
      Offset(.30, .22),
      Offset(.28, .40),
      Offset(.22, .55),
      Offset(.26, .75),
      Offset(.17, .85),
      Offset(.12, .60),
      Offset(.06, .45),
    ],
    [
      Offset(.45, .20),
      Offset(.60, .12),
      Offset(.80, .18),
      Offset(.92, .32),
      Offset(.82, .48),
      Offset(.66, .46),
      Offset(.55, .58),
      Offset(.47, .42),
    ],
    [
      Offset(.50, .60),
      Offset(.60, .58),
      Offset(.66, .72),
      Offset(.58, .88),
      Offset(.50, .76),
    ],
    [Offset(.35, .82), Offset(.42, .80), Offset(.44, .90), Offset(.36, .92)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Offset.zero & size;
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(circle, Paint()..color = AppColors.discountPurple);

    final stripWidth = size.width * 2;
    final shift = animation.value * stripWidth;
    final paint = Paint()..color = const Color(0xFFF0D246);
    for (final dx in [-shift, stripWidth - shift]) {
      for (final points in _continents) {
        canvas.drawPath(
          _blob(points, Size(stripWidth, size.height), dx),
          paint,
        );
      }
    }
  }

  /// Замкнутая гладкая кривая через середины сторон многоугольника.
  Path _blob(List<Offset> points, Size strip, double dx) {
    Offset at(int i) {
      final p = points[i % points.length];
      return Offset(p.dx * strip.width + dx, p.dy * strip.height);
    }

    final start = (at(0) + at(1)) / 2;
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i <= points.length; i++) {
      final control = at(i);
      final end = (at(i) + at(i + 1)) / 2;
      path.quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_GlobePainter old) => false;
}
