import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';

class FinArcAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showNotification;
  final bool showSearch;
  final Function()? onSearchPressed;
  final bool automaticallyImplyLeading;
  
  const FinArcAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showNotification = true,
    this.showSearch = false,
    this.onSearchPressed,
    this.automaticallyImplyLeading = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: 2,
      actions: [
        // Search icon
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed ?? () {
              // Default search action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search not implemented')),
              );
            },
            tooltip: 'Search',
          ),
        
        // Notification icon
        if (showNotification && authProvider.isAuthenticated)
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              // Show notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
            tooltip: 'Notifications',
          ),
          
        // Profile icon
        if (authProvider.isAuthenticated)
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                authProvider.user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushNamed(RouteNames.profile);
            },
            tooltip: 'Profile',
          ),
          
        // Extra actions
        if (actions != null) ...actions!,
        
        const SizedBox(width: 8),
      ],
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}