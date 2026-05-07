import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:el_moza3/Constants.dart';
import 'package:el_moza3/services/auth_service.dart';
import 'package:el_moza3/services/listing_service.dart';
import 'package:el_moza3/services/database_service.dart';
import 'package:el_moza3/screens/service_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Future<void> Function() onRequireLogin;
  final bool hasVerifiedSession;

  const ProfileScreen({
    super.key,
    required this.onRequireLogin,
    required this.hasVerifiedSession,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await user.updateDisplayName(newName);
                await user.reload();
                await DatabaseService.updateUserProfile(
                  uid: user.uid,
                  name: newName,
                );
              }
              if (context.mounted) Navigator.pop(ctx);
              if (mounted) setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Help & Support"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Send us a message and we'll get back to you soon.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your issue...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = AuthService.currentUser?.uid;
              if (userId != null && messageCtrl.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('support').add({
                  'userId': userId,
                  'message': messageCtrl.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Message sent! We'll respond soon."),
                    ),
                  );
                }
              }
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("About الموزّع"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Version 1.0.0",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "B2B Marketplace for business services.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16),
            Text(
              "Contact: support@elmoza3.com",
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showSavedListings(BuildContext context) async {
    final user = AuthService.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSavedSheet(user.uid),
    );
  }

  void _showMyListings(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildMyListingsSheet(user.uid),
    );
  }

  Widget _buildMyListingsSheet(String userId) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background2,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Text(
                  'My Listings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ListingService.getMyListings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final listings = snapshot.data ?? [];

                if (listings.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign_outlined,
                          size: 60,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No listings yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to add listing screen - handled by parent
                          },
                          child: const Text('Create your first listing'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _buildMyListingCard(listing);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListingCard(Map<String, dynamic> listing) {
    final title = listing['title'] as String? ?? '';
    final category = listing['category'] as String? ?? '';
    final price = listing['price'] as String? ?? '';
    final location = listing['location'] as String? ?? '';
    final listingId = listing['id'] as String? ?? '';
    final imageUrl = listing['imageUrl'] as String?;

    return GestureDetector(
      onTap: () async {
        Navigator.pop(context); // Close sheet
        // Get listing data
        final listingData = await ListingService.getListing(listingId);
        if (listingData != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(
                item: listingData,
                onRequireLogin: widget.onRequireLogin,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorders.radiusMedium,
        ),
        child: Row(
          children: [
            // Image or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLighter,
                borderRadius: AppBorders.radiusSmall,
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.miscellaneous_services,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.miscellaneous_services,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Untitled' : title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.isEmpty ? 'Uncategorized' : category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        price.isEmpty ? 'Price negotiable' : price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location.isEmpty ? 'Unknown' : location,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDeleteListing(listingId, title),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteListing(String listingId, String title) async {
    if (listingId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing"),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ListingService.deleteListing(listingId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete listing')),
          );
        }
      }
    }
  }

  Widget _buildSavedSheet(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildSheetContainer([
            const Center(child: CircularProgressIndicator()),
          ]);
        }
        final data = snap.data?.data() as Map<String, dynamic>?;
        final favoriteIds =
            (data?['favoriteIds'] as List<dynamic>?)?.cast<String>() ?? [];
        if (favoriteIds.isEmpty) {
          return _buildSheetContainer([
            const Center(
              child: Text(
                "لا يوجد إعلانات محفوظة",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ]);
        }
        // Fetch actual listings
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            favoriteIds.map(
              (id) => FirebaseFirestore.instance
                  .collection('listings')
                  .doc(id)
                  .get(),
            ),
          ),
          builder: (c, s) {
            if (s.connectionState == ConnectionState.waiting) {
              return _buildSheetContainer([
                const Center(child: CircularProgressIndicator()),
              ]);
            }
            final listings = s.data?.where((d) => d.exists).toList() ?? [];
            if (listings.isEmpty) {
              return _buildSheetContainer([
                const Center(
                  child: Text(
                    "لا يوجد إعلانات محفوظة",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ]);
            }
            return _buildSheetContainer([
              ListView.separated(
                itemCount: listings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final d = listings[idx].data() as Map<String, dynamic>?;
                  final listingId = listings[idx].id;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Close sheet
                      // Get listing data first
                      final listingData = await ListingService.getListing(
                        listingId,
                      );
                      if (listingData != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(
                              item: listingData,
                              onRequireLogin: widget.onRequireLogin,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background2,
                        borderRadius: AppBorders.radiusMedium,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLighter,
                              borderRadius: AppBorders.radiusSmall,
                            ),
                            child: const Icon(
                              Icons.miscellaneous_services,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d?['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                ),
                                Text(
                                  d?['category'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  d?['price'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.error,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ]);
          },
        );
      },
    );
  }

  Widget _buildSheetContainer(List<Widget> children) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "الإعلانات المحفوظة",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: children[0]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return _buildGuest(context);
        if (!widget.hasVerifiedSession || !user.emailVerified) {
          return _buildPendingVerification(context, user);
        }
        return _buildProfile(context, user);
      },
    );
  }

  Widget _buildGuest(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "سجّل دخولك لعرض حسابك",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "سجّل عشان تشوف إعلاناتك and manage your account",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onRequireLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppBorders.radiusMedium,
                      ),
                    ),
                    child: const Text(
                      "تسجيل الدخول",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVerification(BuildContext context, User user) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLighter,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "فعّل بريدك",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email ?? "",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "اضغط على الرابط in your email.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: widget.onRequireLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      "تفعيل الآن",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    return Scaffold(
      backgroundColor: AppColors.background2,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorders.radiusMedium,
                  boxShadow: AppShadows.small,
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLighter,
                            shape: BoxShape.circle,
                          ),
                          child: user.photoURL != null
                              ? ClipOval(
                                  child: Image.network(
                                    user.photoURL!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _showEditDialog(context, user),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName ?? "User",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.email ?? "",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (user.emailVerified) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "Verified",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats - with loading state to prevent showing 0 during stream
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: ListingService.getMyListings(),
                      builder: (context, snap) {
                        // Show loading - never show 0
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _stat("-", "إعلاناتي"),
                              _stat("-", "مشاهدة"),
                              _stat("0", "رسائل"),
                            ],
                          );
                        }
                        final listings = snap.data ?? [];
                        final count = listings.length;
                        int totalViews = 0;
                        for (final l in listings) {
                          totalViews += (l['viewCount'] as int?) ?? 0;
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat("$count", "إعلاناتي"),
                            _stat("$totalViews", "مشاهدة"),
                            _stat("0", "رسائل"),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Menu
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorders.radiusMedium,
                  boxShadow: AppShadows.small,
                ),
                child: Column(
                  children: [
                    _menuItem(
                      Icons.campaign_outlined,
                      "My Listings",
                      onTap: () => _showMyListings(context),
                    ),
                    _divider(),
                    _menuItem(
                      Icons.favorite_outline_rounded,
                      "Saved",
                      onTap: () => _showSavedListings(context),
                    ),
                    _divider(),
                    _menuItem(
                      Icons.settings_outlined,
                      "Settings",
                      onTap: () {},
                    ),
                    _divider(),
                    _menuItem(
                      Icons.help_outline_rounded,
                      "Help & Support",
                      onTap: () => _showHelpDialog(context),
                    ),
                    _divider(),
                    _menuItem(
                      Icons.info_outline_rounded,
                      "About",
                      onTap: () => _showAboutDialog(context),
                    ),
                    _divider(),
                    _menuItem(
                      Icons.logout_rounded,
                      "Logout",
                      color: AppColors.error,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Version 1.0.0",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _menuItem(
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );

  Widget _divider() => const Divider(
    height: 1,
    color: AppColors.border,
    indent: 16,
    endIndent: 16,
  );
}

/// User profile screen - displays other user's data and their listings
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Future<void> Function() onRequireLogin;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.onRequireLogin,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _listings = [];
  bool _isLoading = true;
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final userListings = await _getUserListings();
      final userName = userListings.isNotEmpty
          ? userListings.first['userName'] as String? ?? 'User'
          : 'User';

      int totalViews = 0;
      for (final listing in userListings) {
        totalViews += (listing['viewCount'] as int?) ?? 0;
      }

      if (mounted) {
        setState(() {
          _userData = {'name': userName};
          _listings = userListings;
          _totalViews = totalViews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getUserListings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('userId', isEqualTo: widget.userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background2,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userName = _userData?['name'] as String? ?? 'مستخدم';
    final listingsCount = _listings.length;

    return Scaffold(
      backgroundColor: AppColors.background2,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userName,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppBorders.radiusMedium,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLighter,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat("$listingsCount", "إعلانات"),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _stat("$_totalViews", "مشاهدة"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'إعلانات المستخدم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_listings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorders.radiusMedium,
                ),
                child: const Center(
                  child: Text(
                    'لا يوجد إعلانات',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _listings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _listingCard(_listings[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _listingCard(Map<String, dynamic> listing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.radiusMedium,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLighter,
              borderRadius: AppBorders.radiusSmall,
            ),
            child: const Icon(
              Icons.miscellaneous_services,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                Text(
                  listing['category'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  listing['price'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
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
