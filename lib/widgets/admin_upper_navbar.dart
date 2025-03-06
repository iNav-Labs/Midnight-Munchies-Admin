import 'package:flutter/material.dart';

class AdminUpperNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool isShopOpen;
  final Function(bool) onToggleShopStatus;

  const AdminUpperNavbar({
    super.key,
    required this.isShopOpen,
    required this.onToggleShopStatus,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: AppBar(
        backgroundColor: const Color(0xFF6552FF),
        elevation: 0,
        flexibleSpace: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 25),
                child: Transform.scale(
                  scale: 1.5,
                  child: Image.asset(
                    'assets/images/gormish_logo_white.png',
                    height: 60,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    isShopOpen ? 'Open' : 'Closed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isShopOpen,
                    onChanged: onToggleShopStatus,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
