import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountAnalysisPageView extends StatefulWidget {
  const AccountAnalysisPageView({super.key});

  @override
  State<AccountAnalysisPageView> createState() =>
      _AccountAnalysisPageViewState();
}

class _AccountAnalysisPageViewState extends State<AccountAnalysisPageView> {
  int totalUsers = 0;
  int activeUsers = 0;
  int newUsersThisMonth = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserStats();
  }

  Future<void> fetchUserStats() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    int total = 0;
    int active = 0;
    int newThisMonth = 0;

    for (var doc in snapshot.docs) {
      total++;

      final data = doc.data();
      if (data['is_active'] == true) active++;

      final createdAt = data['created_at'];
      if (createdAt != null && createdAt is Timestamp) {
        final date = createdAt.toDate();
        if (date.month == currentMonth && date.year == currentYear) {
          newThisMonth++;
        }
      }
    }

    setState(() {
      totalUsers = total;
      activeUsers = active;
      newUsersThisMonth = newThisMonth;
      isLoading = false;
    });
  }

  // @override
  // Widget build(BuildContext context) {
  //   // Giả lập dữ liệu phân tích
  //   final int totalUsers = 1342;
  //   final int activeUsers = 842;
  //   final int newUsersThisMonth = 126;
  //
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text(
  //         "Accounts & Analytics",
  //         style: TextStyle(color: Colors.white),
  //       ),
  //       backgroundColor: Colors.blueAccent,
  //       iconTheme: const IconThemeData(color: Colors.white),
  //     ),
  //     backgroundColor: Colors.white,
  //     body: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           _statCard("Total Accounts", totalUsers),
  //           _statCard("Active Users", activeUsers),
  //           _statCard("New Users This Month", newUsersThisMonth),
  //           const SizedBox(height: 24),
  //           const Align(
  //             alignment: Alignment.centerLeft,
  //             child: Text("User List",
  //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  //           ),
  //           const SizedBox(height: 12),
  //           Expanded(child: _buildUserList()),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accounts & Analytics",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _statCard("Total Accounts", totalUsers),
                    _statCard("Active Users", activeUsers),
                    _statCard("New Users This Month", newUsersThisMonth),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "User List",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _buildUserList()),
                  ],
                ),
      ),
    );
  }

  Widget _statCard(String title, int number) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: const Icon(Icons.analytics, color: Colors.blue),
        title: Text(title),
        trailing: Text(
          number.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found."));
        }

        final users = snapshot.data!.docs;

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final data = users[index].data() as Map<String, dynamic>;

            final email = data['email'] ?? 'N/A';
            final fullName = data['full_name'] ?? 'Unknown';
            final role = data['role'] ?? 'user';
            final createdAt =
                data['created_at'] != null
                    ? (data['created_at'] as Timestamp).toDate()
                    : null;
            final avatarUrl = data['avatar'] ?? '';
            final formattedDate =
                createdAt != null
                    ? DateFormat('dd-MM-yyyy').format(createdAt)
                    : 'Unknown';

            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : const AssetImage('assets/images/tennis.png')
                            as ImageProvider,
                radius: 24,
              ),
              title: Text(fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Email: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(email, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        "Role: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(role),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                formattedDate,
                style: const TextStyle(fontSize: 11, color: Colors.black),
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
