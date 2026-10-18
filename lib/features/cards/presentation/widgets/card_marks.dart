import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:material_ui/material_ui.dart';

/// Network mark. Drawn rather than bundled as images; good enough for a
/// wallet UI and adapts to the card's text color.
class NetworkLogo extends StatelessWidget {
  const NetworkLogo({
    required this.network,
    required this.height,
    required this.color,
    super.key,
  });

  final CardNetwork network;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final logo = switch (network) {
      CardNetwork.visa => Text(
        'VISA',
        style: TextStyle(
          color: color,
          fontSize: height * 0.78,
          height: 1,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -0.5,
        ),
      ),
      CardNetwork.mastercard => SizedBox(
        width: height * 1.62,
        height: height,
        child: const CustomPaint(painter: _MastercardPainter()),
      ),
      CardNetwork.amex => Container(
        padding: EdgeInsets.symmetric(horizontal: height * 0.22),
        height: height * 0.8,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2E77BC),
          borderRadius: BorderRadius.circular(height * 0.12),
        ),
        child: Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontSize: height * 0.42,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
      CardNetwork.discover => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DISC',
            style: TextStyle(
              color: color,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            width: height * 0.46,
            height: height * 0.46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF58220),
            ),
          ),
          Text(
            'VER',
            style: TextStyle(
              color: color,
              fontSize: height * 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      CardNetwork.unknown => Icon(
        Icons.credit_card_rounded,
        size: height,
        color: color,
      ),
    };
    return Semantics(
      label: network.label,
      child: ExcludeSemantics(child: logo),
    );
  }
}

class _MastercardPainter extends CustomPainter {
  const _MastercardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    final left = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
    final right = Path()
      ..addOval(Rect.fromCircle(center: Offset(size.width - r, r), radius: r));
    canvas
      ..drawPath(left, Paint()..color = const Color(0xFFEB001B))
      ..drawPath(right, Paint()..color = const Color(0xFFF79E1B))
      ..drawPath(
        Path.combine(PathOperation.intersect, left, right),
        Paint()..color = const Color(0xFFFF5F00),
      );
  }

  @override
  bool shouldRepaint(_MastercardPainter oldDelegate) => false;
}
