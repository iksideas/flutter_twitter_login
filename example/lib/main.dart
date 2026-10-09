import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';

void main() => runApp(new MyApp());

const Color _bgDeep = Color(0xFF05060F);
const Color _cyan = Color(0xFF1DA1F2);
const Color _violet = Color(0xFF7C4DFF);
const Color _pink = Color(0xFFFF4D9D);

enum _Tone { neutral, success, warning, error }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Twitter login sample',
      theme: new ThemeData.dark(),
      home: new LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  static final TwitterLogin twitterLogin = new TwitterLogin(
    consumerKey: 'YOURCONSUMERKEY',
    consumerSecret: 'YOURSECRET',
  );

  AnimationController _bg;
  AnimationController _pulse;
  AnimationController _intro;

  String _message = 'Ready when you are.';
  _Tone _tone = _Tone.neutral;
  bool _loading = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _bg = new AnimationController(
        vsync: this, duration: const Duration(seconds: 24))
      ..repeat();
    _pulse = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat();
    _intro = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();
  }

  @override
  void dispose() {
    _bg.dispose();
    _pulse.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _login() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = 'Contacting Twitter…';
      _tone = _Tone.neutral;
    });

    String newMessage;
    _Tone newTone;
    bool loggedIn = false;

    try {
      final TwitterLoginResult result = await twitterLogin.authorize();
      switch (result.status) {
        case TwitterLoginStatus.loggedIn:
          newMessage = 'Logged in! username: ${result.session.username}';
          newTone = _Tone.success;
          loggedIn = true;
          break;
        case TwitterLoginStatus.cancelledByUser:
          newMessage = 'Login cancelled by user.';
          newTone = _Tone.warning;
          break;
        case TwitterLoginStatus.error:
          newMessage = 'Login error: ${result.errorMessage}';
          newTone = _Tone.error;
          break;
      }
    } catch (e) {
      newMessage = 'Login error: $e';
      newTone = _Tone.error;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _loggedIn = loggedIn;
      _message = newMessage;
      _tone = newTone;
    });
  }

  void _logout() async {
    await twitterLogin.logOut();
    if (!mounted) return;
    setState(() {
      _loggedIn = false;
      _message = 'Logged out.';
      _tone = _Tone.neutral;
    });
  }

  /// Fades and lifts [child] in during the [begin]..[end] slice of the intro.
  Widget _reveal(double begin, double end, Widget child) {
    final Interval curve =
        new Interval(begin, end, curve: Curves.easeOutCubic);
    return new AnimatedBuilder(
      animation: _intro,
      child: child,
      builder: (BuildContext context, Widget child) {
        final double v = curve.transform(_intro.value);
        return new Opacity(
          opacity: v,
          child: new Transform.translate(
            offset: new Offset(0.0, 36.0 * (1.0 - v)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: _bgDeep,
      body: new Stack(
        fit: StackFit.expand,
        children: <Widget>[
          new AnimatedBuilder(
            animation: _bg,
            builder: (BuildContext context, Widget child) => new CustomPaint(
                  painter: new _AuroraPainter(_bg.value),
                ),
          ),
          new SafeArea(
            child: new Center(
              child: new SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                child: new ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420.0),
                  child: _reveal(0.0, 0.75, _buildCard()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return new ClipRRect(
      borderRadius: new BorderRadius.circular(32.0),
      child: new BackdropFilter(
        filter: new ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
        child: new Container(
          padding: const EdgeInsets.fromLTRB(28.0, 36.0, 28.0, 32.0),
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.circular(32.0),
            border: new Border.all(color: Colors.white.withOpacity(0.18)),
            gradient: new LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withOpacity(0.14),
                Colors.white.withOpacity(0.04),
              ],
            ),
          ),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _reveal(0.15, 0.6, _buildLogo()),
              const SizedBox(height: 28.0),
              _reveal(0.3, 0.8, _buildHeadline()),
              const SizedBox(height: 24.0),
              _reveal(0.4, 0.9, _buildStatus()),
              const SizedBox(height: 28.0),
              _reveal(
                0.5,
                1.0,
                new _GlowButton(
                  label: _loggedIn ? 'Sign in again' : 'Sign in with Twitter',
                  icon: Icons.alternate_email,
                  loading: _loading,
                  onPressed: _login,
                ),
              ),
              new AnimatedCrossFade(
                duration: const Duration(milliseconds: 350),
                crossFadeState: _loggedIn
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: new Padding(
                  padding: const EdgeInsets.only(top: 14.0),
                  child: new _GhostButton(
                    label: 'Log out',
                    onPressed: _logout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return new SizedBox(
      width: 150.0,
      height: 150.0,
      child: new AnimatedBuilder(
        animation: new Listenable.merge(<Listenable>[_pulse, _bg]),
        builder: (BuildContext context, Widget child) {
          final List<Widget> layers = <Widget>[];
          // Two expanding "sonar" rings, half a cycle apart.
          for (int i = 0; i < 2; i++) {
            final double p = (_pulse.value + i * 0.5) % 1.0;
            layers.add(new Opacity(
              opacity: (1.0 - p) * 0.55,
              child: new Transform.scale(
                scale: 0.62 + p * 0.38,
                child: new Container(
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    border: new Border.all(color: _cyan, width: 2.0),
                  ),
                ),
              ),
            ));
          }
          // Slowly spinning gradient halo.
          layers.add(new Transform.rotate(
            angle: _bg.value * math.pi * 2 * 6,
            child: new Container(
              margin: const EdgeInsets.all(22.0),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: <Color>[_cyan, _violet, _pink, _cyan],
                ),
              ),
            ),
          ));
          // Core disc with breathing glow.
          final double breath =
              0.5 + 0.5 * math.sin(_pulse.value * math.pi * 2);
          layers.add(new Container(
            margin: const EdgeInsets.all(27.0),
            decoration: new BoxDecoration(
              shape: BoxShape.circle,
              color: _bgDeep,
              boxShadow: <BoxShadow>[
                new BoxShadow(
                  color: _cyan.withOpacity(0.25 + 0.35 * breath),
                  blurRadius: 18.0 + 22.0 * breath,
                  spreadRadius: 1.0 + 3.0 * breath,
                ),
              ],
            ),
            child: const Center(
              child: const Icon(Icons.alternate_email,
                  size: 44.0, color: Colors.white),
            ),
          ));
          return new Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: layers);
        },
      ),
    );
  }

  Widget _buildHeadline() {
    return new Column(
      children: <Widget>[
        new ShaderMask(
          shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Colors.white, Color(0xFFB9E6FF), _cyan],
              ).createShader(bounds),
          child: const Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        new Text(
          'One tap to connect your account\nand jump right in.',
          textAlign: TextAlign.center,
          style: new TextStyle(
            fontSize: 15.0,
            height: 1.4,
            color: Colors.white.withOpacity(0.62),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    Color color;
    IconData icon;
    switch (_tone) {
      case _Tone.success:
        color = const Color(0xFF3DDC97);
        icon = Icons.check_circle;
        break;
      case _Tone.warning:
        color = const Color(0xFFFFB74D);
        icon = Icons.info;
        break;
      case _Tone.error:
        color = const Color(0xFFFF6B6B);
        icon = Icons.error;
        break;
      default:
        color = Colors.white70;
        icon = Icons.bolt;
    }

    return new AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return new FadeTransition(
          opacity: animation,
          child: new ScaleTransition(
            scale: new Tween<double>(begin: 0.9, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: new Container(
        key: new ValueKey<String>('$_tone|$_message'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: new BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: new BorderRadius.circular(16.0),
          border: new Border.all(color: color.withOpacity(0.45)),
        ),
        child: new Row(
          children: <Widget>[
            new Icon(icon, size: 20.0, color: color),
            const SizedBox(width: 10.0),
            new Expanded(
              child: new Text(
                _message,
                style: new TextStyle(
                    fontSize: 14.0, color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary call-to-action: gradient, glow, press-scale and loading state.
class _GlowButton extends StatefulWidget {
  const _GlowButton({
    this.label,
    this.icon,
    this.loading,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  @override
  _GlowButtonState createState() => new _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.loading ? null : widget.onPressed,
      child: new Transform.scale(
        scale: _down ? 0.96 : 1.0,
        child: new AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          height: 56.0,
          width: double.infinity,
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.circular(18.0),
            gradient: const LinearGradient(
              colors: <Color>[_cyan, _violet, _pink],
            ),
            boxShadow: <BoxShadow>[
              new BoxShadow(
                color: _violet.withOpacity(widget.loading ? 0.25 : 0.55),
                blurRadius: _down ? 12.0 : 28.0,
                offset: new Offset(0.0, _down ? 4.0 : 10.0),
              ),
            ],
          ),
          child: new Center(
            child: new AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: widget.loading
                  ? const SizedBox(
                      key: const ValueKey<String>('spinner'),
                      width: 24.0,
                      height: 24.0,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : new Row(
                      key: const ValueKey<String>('label'),
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        new Icon(widget.icon, color: Colors.white, size: 22.0),
                        const SizedBox(width: 10.0),
                        new Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({this.label, this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return new SizedBox(
      width: double.infinity,
      height: 50.0,
      child: new GestureDetector(
        onTap: onPressed,
        child: new Container(
          alignment: Alignment.center,
          decoration: new BoxDecoration(
            borderRadius: new BorderRadius.circular(16.0),
            border: new Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: new Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15.0),
          ),
        ),
      ),
    );
  }
}

/// Drifting aurora orbs plus a twinkling starfield.
class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.t) {
    final math.Random rnd = new math.Random(7);
    for (int i = 0; i < 46; i++) {
      _stars.add(<double>[
        rnd.nextDouble(), // x
        rnd.nextDouble(), // y
        0.6 + rnd.nextDouble() * 1.6, // radius
        rnd.nextDouble() * math.pi * 2, // twinkle phase
        0.4 + rnd.nextDouble() * 1.2, // twinkle speed
      ]);
    }
  }

  final double t;
  final List<List<double>> _stars = <List<double>>[];

  static const List<Color> _orbColors = const <Color>[_cyan, _violet, _pink];

  @override
  void paint(Canvas canvas, Size size) {
    final double tau = math.pi * 2;

    canvas.drawRect(
      Offset.zero & size,
      new Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF0B1030), _bgDeep],
        ).createShader(Offset.zero & size),
    );

    final double base = math.max(size.width, size.height);
    for (int i = 0; i < _orbColors.length; i++) {
      final double a = t * tau * (i + 1) + i * 2.1;
      final Offset c = new Offset(
        size.width * (0.5 + 0.38 * math.cos(a)),
        size.height * (0.5 + 0.32 * math.sin(a * 0.9 + i)),
      );
      final double r = base * (0.38 + 0.06 * math.sin(a * 1.7));
      canvas.drawCircle(
        c,
        r,
        new Paint()
          ..shader = new RadialGradient(
            colors: <Color>[
              _orbColors[i].withOpacity(0.55),
              _orbColors[i].withOpacity(0.0),
            ],
          ).createShader(new Rect.fromCircle(center: c, radius: r)),
      );
    }

    final Paint star = new Paint();
    for (final List<double> s in _stars) {
      final double twinkle = 0.5 + 0.5 * math.sin(t * tau * 12 * s[4] + s[3]);
      star.color = Colors.white.withOpacity(0.12 + 0.6 * twinkle);
      canvas.drawCircle(
        new Offset(s[0] * size.width, s[1] * size.height),
        s[2] * (0.7 + 0.5 * twinkle),
        star,
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.t != t;
}
