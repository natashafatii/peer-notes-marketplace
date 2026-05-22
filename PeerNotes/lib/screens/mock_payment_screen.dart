import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../services/purchase_service.dart';
import '../widgets/custom_button.dart';

class MockPaymentScreen extends StatefulWidget {
  final Note note;

  const MockPaymentScreen({super.key, required this.note});

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  String _selectedMethod = 'card'; // 'card', 'jazzcash', 'easypaisa'
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardNumberController.text = '4242 4242 4242 4242';
    _expiryController.text = '12/26';
    _cvvController.text = '123';
    _mobileController.text = '0300 1234567';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      final success = await _purchaseService.completePurchase(widget.note);

      if (success && mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, size: 80, color: Colors.green.shade600),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You have successfully unlocked "${widget.note.title}". You can now download and view it anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'START LEARNING',
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context, true); // Return to detail screen with success flag
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOrderSummary(),
                        const SizedBox(height: 32),
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethods(),
                        const SizedBox(height: 32),
                        const Text(
                          'Payment Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentForm(),
                        const SizedBox(height: 40),
                        _buildPayButton(),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            '🔒 Secure 256-bit SSL Mock Encryption',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const Text(
            'Checkout',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 4),
                Text(
                  'DEMO MODE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.note.isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.note.category,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Amount to Pay', style: TextStyle(fontWeight: FontWeight.w500)),
              Row(
                children: [
                  Icon(Icons.toll_rounded, size: 20, color: Colors.indigo.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '₹${widget.note.price}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Row(
      children: [
        _buildMethodCard('card', Icons.credit_card_rounded, 'Card', Colors.indigo),
        const SizedBox(width: 12),
        _buildMethodCard('jazzcash', Icons.phone_android_rounded, 'JazzCash', Colors.green),
        const SizedBox(width: 12),
        _buildMethodCard('easypaisa', Icons.account_balance_wallet_rounded, 'EasyPaisa', Colors.red),
      ],
    );
  }

  Widget _buildMethodCard(String id, IconData icon, String label, Color color) {
    bool isSelected = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedMethod == 'card') {
      return Column(
        children: [
          _buildTextField(
            controller: _cardNumberController,
            label: 'Card Number',
            hint: '0000 0000 0000 0000',
            icon: Icons.payment_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expiryController,
                  label: 'Expiry',
                  hint: 'MM/YY',
                  icon: Icons.calendar_today_rounded,
                  keyboardType: TextInputType.datetime,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cvvController,
                  label: 'CVV',
                  hint: '***',
                  icon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      String label = _selectedMethod == 'jazzcash' ? 'JazzCash Number' : 'EasyPaisa Number';
      Color color = _selectedMethod == 'jazzcash' ? Colors.green : Colors.red;
      return _buildTextField(
        controller: _mobileController,
        label: label,
        hint: '03xx xxxxxxx',
        icon: Icons.phone_iphone_rounded,
        keyboardType: TextInputType.phone,
        activeColor: color,
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Color? activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: activeColor ?? Theme.of(context).colorScheme.primary, width: 2),
            ),
            errorStyle: const TextStyle(height: 0),
          ),
          validator: (value) => (value == null || value.isEmpty) ? '' : null,
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'PAY ₹${widget.note.price}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
