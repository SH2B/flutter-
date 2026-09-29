import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFd9d9d9),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _storedValue = '0';
  String? _pendingOperation;
  bool _isNewInput = true;
  bool _justEvaluated = false;

  void _appendDigit(String digit) {
    setState(() {
      if (_justEvaluated) {
        _display = '0';
        _justEvaluated = false;
      }

      if (_isNewInput || _display == '0') {
        _display = digit;
        _isNewInput = false;
        return;
      }

      if (_display.length < 16) {
        _display += digit;
      }
    });
  }

  void _appendDecimal() {
    setState(() {
      if (_justEvaluated) {
        _display = '0';
        _justEvaluated = false;
      }
      if (_isNewInput) {
        _display = '0.';
        _isNewInput = false;
        return;
      }
      if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _handleOperation(String operation) {
    setState(() {
      if (_pendingOperation != null && !_isNewInput) {
        _calculateResult(forceKeepDisplay: true);
      }

      _storedValue = _display;
      _pendingOperation = operation;
      _isNewInput = true;
    });
  }

  void _calculateResult({bool forceKeepDisplay = false}) {
    if (_pendingOperation == null ||
        _storedValue == '0' && _display == '0' && !forceKeepDisplay) {
      return;
    }

    final left = double.tryParse(_storedValue) ?? 0;
    final right = double.tryParse(_display) ?? 0;
    double result = 0;

    switch (_pendingOperation) {
      case '+':
        result = left + right;
        break;
      case '-':
        result = left - right;
        break;
      case '×':
        result = left * right;
        break;
      case '÷':
        result = right == 0 ? double.nan : left / right;
        break;
    }

    if (result.isNaN) {
      _display = '오류';
      _storedValue = '0';
      _pendingOperation = null;
      _isNewInput = true;
      _justEvaluated = true;
      return;
    }

    final formatted = _formatNumber(result);
    _display = formatted;
    _storedValue = formatted;
    _pendingOperation = forceKeepDisplay ? _pendingOperation : null;
    _isNewInput = true;
    _justEvaluated = true;
  }

  void _equals() {
    setState(() {
      if (_pendingOperation == null) {
        return;
      }

      _calculateResult();
    });
  }

  void _clearAll() {
    setState(() {
      _display = '0';
      _storedValue = '0';
      _pendingOperation = null;
      _isNewInput = true;
      _justEvaluated = false;
    });
  }

  void _clearEntry() {
    setState(() {
      _display = '0';
      _isNewInput = true;
    });
  }

  void _deleteDigit() {
    setState(() {
      if (_justEvaluated) {
        _display = '0';
        _justEvaluated = false;
        return;
      }

      if (_display.length <= 1 || _display == '-0') {
        _display = '0';
        _isNewInput = true;
        return;
      }

      _display = _display.substring(0, _display.length - 1);
      if (_display == '-0') {
        _display = '0';
      }
      if (_display == '') {
        _display = '0';
      }
      _isNewInput = _display == '0';
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0' || _display == '오류') {
        return;
      }

      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _applyPercent() {
    setState(() {
      if (_display == '오류') {
        return;
      }

      final value = double.tryParse(_display) ?? 0;
      _display = _formatNumber(value / 100);
      _isNewInput = true;
    });
  }

  String _formatNumber(double value) {
    if (value.isNaN) {
      return '오류';
    }

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    final formatted = value
        .toStringAsFixed(10)
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'(\.\d*?)0+$'), r'$1');
    return formatted.length > 16 ? formatted.substring(0, 16) : formatted;
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: SizedBox(
              height: 54,
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: label.length > 2 ? 22 : 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFd8d8d8),
      body: Center(
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxHeight: 620),
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFebebeb),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFc7c7c7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFf3f3f3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Text(
                      '계산기',
                      style: TextStyle(
                        color: Color(0xFF2a2a2a),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _windowButton(color: const Color(0xFFa7a7a7)),
                    const SizedBox(width: 8),
                    _windowButton(color: const Color(0xFFc2c2c2)),
                    const SizedBox(width: 8),
                    _windowButton(color: const Color(0xFFd16868)),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF1d1d1d),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildButton(
                            label: '%',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _applyPercent,
                          ),
                          _buildButton(
                            label: 'CE',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _clearEntry,
                          ),
                          _buildButton(
                            label: 'C',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _clearAll,
                          ),
                          _buildButton(
                            label: '⌫',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _deleteDigit,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            label: '1/x',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () {},
                          ),
                          _buildButton(
                            label: 'x²',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () {},
                          ),
                          _buildButton(
                            label: '√',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () {},
                          ),
                          _buildButton(
                            label: '÷',
                            color: const Color(0xFFf6f6f6),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _handleOperation('÷'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            label: '7',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('7'),
                          ),
                          _buildButton(
                            label: '8',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('8'),
                          ),
                          _buildButton(
                            label: '9',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('9'),
                          ),
                          _buildButton(
                            label: '×',
                            color: const Color(0xFFf6f6f6),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _handleOperation('×'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            label: '4',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('4'),
                          ),
                          _buildButton(
                            label: '5',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('5'),
                          ),
                          _buildButton(
                            label: '6',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('6'),
                          ),
                          _buildButton(
                            label: '-',
                            color: const Color(0xFFf6f6f6),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _handleOperation('-'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            label: '1',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('1'),
                          ),
                          _buildButton(
                            label: '2',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('2'),
                          ),
                          _buildButton(
                            label: '3',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('3'),
                          ),
                          _buildButton(
                            label: '+',
                            color: const Color(0xFFf6f6f6),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _handleOperation('+'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildButton(
                            label: '±',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _toggleSign,
                          ),
                          _buildButton(
                            label: '0',
                            color: const Color(0xFFfafafa),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: () => _appendDigit('0'),
                          ),
                          _buildButton(
                            label: '.',
                            color: const Color(0xFFf0f0f0),
                            textColor: const Color(0xFF1d1d1d),
                            onPressed: _appendDecimal,
                          ),
                          _buildButton(
                            label: '=',
                            color: const Color(0xFFdfeaf9),
                            textColor: const Color(0xFF0d3d78),
                            onPressed: _equals,
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
      ),
    );
  }

  static Widget _windowButton({required Color color}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
