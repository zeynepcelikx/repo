import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../business/business_home.dart';
import '../customer/customer_main_layout.dart'; // <-- YENİ IMPORT (Ana İskelet)

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Varsayılan rol: Müşteri
  String _selectedRole = 'customer';
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Kayıt işlemini başlat
      UserModel? newUser = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );

      if (!mounted) return;

      if (newUser != null) {
        // 2. Başarılıysa yönlendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt Başarılı! Hoşgeldiniz 🎉"), backgroundColor: Colors.green),
        );

        if (newUser.role == 'business') {
          // İşletme Paneline
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BusinessHomeScreen()),
                (route) => false,
          );
        } else {
          // Müşteri -> ALT MENÜLÜ ANA SAYFAYA (Layout)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainLayout()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aramıza Katıl")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 80, color: Colors.green),
                const SizedBox(height: 20),

                // ROL SEÇİMİ (TOGGLE)
                const Text("Hangi amaçla kullanacaksın?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'customer'),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'customer' ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedRole == 'customer' ? Colors.green : Colors.grey),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.fastfood, color: _selectedRole == 'customer' ? Colors.white : Colors.black),
                              const Text("Yemek Al", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'business'),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _selectedRole == 'business' ? Colors.black : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedRole == 'business' ? Colors.black : Colors.grey),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.store, color: _selectedRole == 'business' ? Colors.white : Colors.black),
                              const Text("Satış Yap", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "E-Posta Adresi",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.contains('@') ? null : "Geçerli bir mail girin",
                ),
                const SizedBox(height: 15),

                // ŞİFRE
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Şifre Belirle",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.length < 6 ? "Şifre en az 6 karakter olmalı" : null,
                ),
                const SizedBox(height: 30),

                // BUTON
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedRole == 'customer' ? Colors.green : Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(_selectedRole == 'customer'
                      ? "MÜŞTERİ OLARAK KAYDOL"
                      : "İŞLETME OLARAK KAYDOL"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}