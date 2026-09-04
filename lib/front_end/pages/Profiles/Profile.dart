import 'package:electrocitybd1/front_end/All_Pages/Registrations/signup.dart'
    show Signup;
import 'package:electrocitybd1/config/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../All_Pages/CART/Cart_provider.dart';
import '../../All_Pages/CART/Orders.dart'; // Import OrderModel and OrderItem from Orders.dart
import '../../Dimensions/responsive_dimensions.dart';
import '../../Provider/Orders_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/auth_session.dart';
import '../../widgets/footer.dart';
import '../../widgets/header.dart';
import 'My_order.dart';
import 'Wishlist_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String selectedMenu = "Personal Information";

  // Edit mode flag for personal info
  bool isEditingPersonalInfo = false;

  // Password visibility flags
  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  // Personal Info Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedGender = "Male";

  // Password Controllers
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Address Controllers
  final TextEditingController streetAddressController = TextEditingController();
  final TextEditingController buildingAddressController =
      TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();

  // Card Controllers
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  bool saveCardForFuture = false;

  // Lists for stored data (loaded from DB / profile; name & address used in orders)
  List<Map<String, String>> addresses = [];

  // User-added card methods only
  List<Map<String, String>> paymentMethods = [];

  // Orders loaded from API when user opens My Orders (see MyOrdersPage)
  List<OrderModel> myLiveOrders = [];

  // Responsive helpers
  double _radius(BuildContext context, {double factor = 1}) =>
      AppDimensions.borderRadius(context) * factor;

  double _icon(BuildContext context, {double factor = 1}) =>
      AppDimensions.iconSize(context) * factor;

  double _drawerAvatarRadius(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 28,
      mobile: 32,
      tablet: 36,
      smallDesktop: 40,
      desktop: 42,
    );
  }

  double _logoutIconSize(BuildContext context) {
    final r = AppResponsive.of(context);
    return r.value(
      smallMobile: 52,
      mobile: 60,
      tablet: 68,
      smallDesktop: 76,
      desktop: 84,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await ApiService.getProfile();
      if (!mounted) return;
      final userData = UserData.fromApiResponse(profile);
      await AuthSession.updateUserData(userData);
      setState(() {
        firstNameController.text = userData.firstName;
        lastNameController.text = userData.lastName;
        emailController.text = userData.email;
        phoneController.text = userData.phone;
        selectedGender = userData.gender;
        if (userData.address.isNotEmpty) {
          addresses = [
            {'address': userData.address},
          ];
        }
      });
      return;
    } catch (e) {
      // API failed, fall back to locally cached user data
      if (kDebugMode) print('Profile API error: $e');
    }
    final userData = await AuthSession.getUserData();
    if (userData != null && mounted) {
      setState(() {
        firstNameController.text = userData.firstName;
        lastNameController.text = userData.lastName;
        emailController.text = userData.email;
        phoneController.text = userData.phone;
        selectedGender = userData.gender;
        if (userData.address.isNotEmpty) {
          addresses = [
            {'address': userData.address},
          ];
        }
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    streetAddressController.dispose();
    buildingAddressController.dispose();
    cityController.dispose();
    zipCodeController.dispose();
    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive.of(context);
    final horizontalPadding = r.value(
      smallMobile: 16.0,
      mobile: 16.0,
      tablet: 40.0,
      smallDesktop: 60.0,
      desktop: 100.0,
    );
    final verticalPadding = r.value(
      smallMobile: 20.0,
      mobile: 20.0,
      tablet: 30.0,
      smallDesktop: 35.0,
      desktop: 40.0,
    );

    final isMobileOrTablet = r.isTablet || r.isMobile || r.isSmallMobile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      // Add Drawer for Mobile & Tablet
      drawer: isMobileOrTablet ? _buildProfileDrawer() : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  SizedBox(height: verticalPadding),
                  // Desktop Layout - Show Sidebar
                  if (!isMobileOrTablet)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sidebar Navigation
                        Expanded(flex: 1, child: _buildSidebar()),
                        SizedBox(width: horizontalPadding),
                        // Profile Form
                        Expanded(flex: 3, child: _buildProfileForm()),
                      ],
                    ),
                  // Mobile & Tablet Layout - Only Show Form
                  if (isMobileOrTablet) _buildProfileForm(),
                  SizedBox(height: verticalPadding * 2),
                ],
              ),
            ),
            // Footer - Full Width, always at bottom
            const FooterSection(),
          ],
        ),
      ),
    );
  }

  // Profile Menu Drawer for Mobile & Tablet
  Widget _buildProfileDrawer() {
    final padding = AppDimensions.padding(context);
    List<String> menuItems = [
      "Personal Information",
      "My Orders",
      "Manage Address",
      "Payment Method",
      "Password Manager",
      "Logout",
    ];

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.orangeAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: EdgeInsets.all(padding * 1.5),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: _drawerAvatarRadius(context),
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: _drawerAvatarRadius(context),
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: padding),
                    Text(
                      "${firstNameController.text} ${lastNameController.text}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppDimensions.titleFont(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: padding / 4),
                    Text(
                      emailController.text,
                      style: TextStyle(
                        color: const Color(0xE6FFFFFF),
                        fontSize: AppDimensions.smallFont(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white, thickness: 1, height: 1),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    vertical: padding,
                    horizontal: padding / 2,
                  ),
                  children: menuItems.map((item) {
                    bool isSelected = item == selectedMenu;
                    IconData icon;

                    switch (item) {
                      case "Personal Information":
                        icon = Icons.person;
                        break;
                      case "My Orders":
                        icon = Icons.shopping_bag;
                        break;
                      case "Manage Address":
                        icon = Icons.location_on;
                        break;
                      case "Payment Method":
                        icon = Icons.payment;
                        break;
                      case "Password Manager":
                        icon = Icons.lock;
                        break;
                      case "Logout":
                        icon = Icons.logout;
                        break;
                      default:
                        icon = Icons.circle;
                    }

                    return Container(
                      margin: EdgeInsets.only(bottom: padding / 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0x33FFFFFF),
                        borderRadius: BorderRadius.circular(_radius(context)),
                      ),
                      child: ListTile(
                        leading: Icon(
                          icon,
                          color: isSelected ? Colors.orange : Colors.white,
                          size: _icon(context),
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontSize: AppDimensions.bodyFont(context),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected ? Colors.orange : Colors.white,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isSelected ? Colors.orange : Colors.white,
                          size: _icon(context, factor: 0.9),
                        ),
                        onTap: () {
                          setState(() {
                            selectedMenu = item;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final r = AppResponsive.of(context);
    List<String> menuItems = [
      "Personal Information",
      "My Orders",
      "Manage Address",
      "Payment Method",
      "Password Manager",
      "Logout",
    ];

    return Column(
      children: menuItems.map((item) {
        bool isSelected = item == selectedMenu;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedMenu = item;
            });
          },
          child: Container(
            margin: EdgeInsets.only(
              bottom: r.value(
                smallMobile: 8,
                mobile: 8,
                tablet: 10,
                smallDesktop: 10,
                desktop: 10,
              ),
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD23F) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey300),
            ),
            child: ListTile(
              title: Text(
                item,
                style: TextStyle(
                  fontSize: AppDimensions.bodyFont(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                size: _icon(context, factor: 0.85),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileForm() {
    switch (selectedMenu) {
      case "Personal Information":
        return _buildPersonalInfo();
      case "My Orders":
        return const MyOrdersPage();
      case "Manage Address":
        return _buildManageAddress();
      case "Payment Method":
        return _buildPaymentMethod();
      case "Password Manager":
        return _buildPasswordManager();
      case "Logout":
        return _buildLogout();
      default:
        return _buildPersonalInfo();
    }
  }

  Widget _buildPersonalInfo() {
    final r = AppResponsive.of(context);
    final padding = AppDimensions.padding(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Edit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: AppDimensions.titleFont(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isEditingPersonalInfo)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isEditingPersonalInfo = true;
                      });
                    },
                    icon: const Icon(Icons.edit, color: Colors.blue),
                  ),
              ],
            ),
            SizedBox(height: padding),
            // Profile Image
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grey300, width: 2),
                ),
                child: CircleAvatar(
                  radius: r.value(
                    smallMobile: 50,
                    mobile: 50,
                    tablet: 60,
                    smallDesktop: 65,
                    desktop: 70,
                  ),
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: r.value(
                      smallMobile: 50.0,
                      mobile: 50.0,
                      tablet: 60.0,
                      smallDesktop: 65.0,
                      desktop: 70.0,
                    ),
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
            SizedBox(height: padding * 1.5),
            // Form Fields
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                r.isMobile || r.isSmallMobile
                    ? Column(
                        children: [
                          _buildEditableTextField(
                            "First Name *",
                            "Leslie",
                            controller: firstNameController,
                            enabled: isEditingPersonalInfo,
                          ),
                          _buildEditableTextField(
                            "Last Name *",
                            "Last Name",
                            controller: lastNameController,
                            enabled: isEditingPersonalInfo,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildEditableTextField(
                              "First Name *",
                              "First Name",
                              controller: firstNameController,
                              enabled: isEditingPersonalInfo,
                            ),
                          ),
                          SizedBox(width: padding),
                          Expanded(
                            child: _buildEditableTextField(
                              "Last Name *",
                              "Last Name",
                              controller: lastNameController,
                              enabled: isEditingPersonalInfo,
                            ),
                          ),
                        ],
                      ),
                _buildEditableTextField(
                  "Email *",
                  "example@gmail.com",
                  controller: emailController,
                  enabled: isEditingPersonalInfo,
                ),
                _buildEditableTextField(
                  "Phone *",
                  "+0123-456-789",
                  controller: phoneController,
                  enabled: isEditingPersonalInfo,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gender *",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppDimensions.bodyFont(context),
                        ),
                      ),
                      SizedBox(height: padding / 2),
                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        disabledHint: Text(selectedGender),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: padding,
                            vertical: padding * 0.75,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.grey300,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: AppColors.grey300,
                              width: 1,
                            ),
                          ),
                        ),
                        items: ["Male", "Female", "Other"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: isEditingPersonalInfo
                            ? (String? newValue) {
                                setState(() {
                                  selectedGender = newValue!;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            // Action Buttons
            if (isEditingPersonalInfo)
              r.isMobile || r.isSmallMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.yellow],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _updatePersonalInfo();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                  vertical: padding * 0.75,
                                ),
                                child: Text(
                                  "Save Changes",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppDimensions.bodyFont(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: padding),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isEditingPersonalInfo = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.grey300),
                            padding: EdgeInsets.symmetric(
                              horizontal: padding,
                              vertical: padding * 0.75,
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.red, Colors.yellow],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _updatePersonalInfo();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding * 1.5,
                                  vertical: padding * 0.75,
                                ),
                                child: Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppDimensions.bodyFont(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: padding),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isEditingPersonalInfo = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.grey300),
                            padding: EdgeInsets.symmetric(
                              horizontal: padding * 1.5,
                              vertical: padding * 0.75,
                            ),
                          ),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageAddress() {
    final padding = AppDimensions.padding(context);
    final r = AppResponsive.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Manage Address",
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: padding),
                  child: Padding(
                    padding: EdgeInsets.all(padding * 0.75),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                addresses[index]["address"]!,
                                style: TextStyle(
                                  color: AppColors.grey300,
                                  fontSize: AppDimensions.smallFont(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                final currentAddress =
                                    addresses[index]["address"] ?? '';
                                final controller = TextEditingController(
                                  text: currentAddress,
                                );
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Edit Address'),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter your address',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final newAddr = controller.text
                                              .trim();
                                          if (newAddr.isEmpty) return;
                                          Navigator.pop(ctx);
                                          setState(
                                            () => addresses[index]["address"] =
                                                newAddr,
                                          );
                                          final primaryAddress =
                                              addresses.isNotEmpty
                                              ? (addresses.first['address'] ??
                                                    '')
                                              : '';
                                          try {
                                            await ApiService.updateProfile({
                                              'address': primaryAddress,
                                            });
                                            if (mounted)
                                              _showSnackBar(
                                                'Address updated!',
                                                Colors.green,
                                              );
                                          } catch (e) {
                                            if (mounted)
                                              _showSnackBar(
                                                'Saved locally. Sync failed.',
                                                Colors.orange,
                                              );
                                          }
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                "Edit",
                                style: TextStyle(
                                  fontSize: AppDimensions.smallFont(context),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteAddress(index);
                              },
                              child: Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: AppDimensions.smallFont(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: padding),
            const Divider(),
            SizedBox(height: padding),
            Text(
              "Add New Address",
              style: TextStyle(
                fontSize: AppDimensions.bodyFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding),
            _buildTextField(
              "Street Address *",
              "Enter Street Address",
              controller: streetAddressController,
            ),
            _buildTextField(
              "Building/Apartment",
              "Enter Building / Apartment",
              controller: buildingAddressController,
            ),
            r.isMobile || r.isSmallMobile
                ? Column(
                    children: [
                      _buildTextField(
                        "City *",
                        "Select City",
                        controller: cityController,
                      ),
                      _buildTextField(
                        "Zip Code *",
                        "Enter Zip Code",
                        controller: zipCodeController,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          "City *",
                          "Select City",
                          controller: cityController,
                        ),
                      ),
                      SizedBox(width: padding),
                      Expanded(
                        child: _buildTextField(
                          "Zip Code *",
                          "Enter Zip Code",
                          controller: zipCodeController,
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7340),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.5,
                    vertical: padding * 0.75,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Add Address",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.bodyFont(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Payment Method
  Widget _buildPaymentMethod() {
    final padding = AppDimensions.padding(context);
    final r = AppResponsive.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Methods",
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding),
            // Card Section
            Text(
              "Cards",
              style: TextStyle(
                fontSize: AppDimensions.bodyFont(context),
                fontWeight: FontWeight.w600,
                color: AppColors.grey300,
              ),
            ),
            SizedBox(height: padding / 2),
            if (paymentMethods.isEmpty)
              Text(
                "No saved cards yet",
                style: TextStyle(
                  color: AppColors.grey300,
                  fontSize: AppDimensions.bodyFont(context),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  return _buildPaymentItem(
                    paymentMethods[index]["type"]!,
                    paymentMethods[index]["status"]!,
                  );
                },
              ),

            SizedBox(height: padding),
            const Divider(),
            SizedBox(height: padding),
            Text(
              "Add New Card",
              style: TextStyle(
                fontSize: AppDimensions.bodyFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding),
            _buildTextField(
              "Card Holder Name *",
              "Ex. John Doe",
              controller: cardHolderController,
            ),
            _buildTextField(
              "Card Number *",
              "1234 5678 9012 3456",
              controller: cardNumberController,
            ),
            r.isMobile || r.isSmallMobile
                ? Column(
                    children: [
                      _buildTextField(
                        "Expiry Date *",
                        "MM/YY",
                        controller: expiryDateController,
                      ),
                      _buildTextField(
                        "CVV *",
                        "***",
                        controller: cvvController,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          "Expiry Date *",
                          "MM/YY",
                          controller: expiryDateController,
                        ),
                      ),
                      SizedBox(width: padding),
                      Expanded(
                        child: _buildTextField(
                          "CVV *",
                          "***",
                          controller: cvvController,
                        ),
                      ),
                    ],
                  ),
            Row(
              children: [
                Checkbox(
                  value: saveCardForFuture,
                  onChanged: (value) {
                    setState(() {
                      saveCardForFuture = value!;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    "Save card for future payments",
                    style: TextStyle(fontSize: AppDimensions.bodyFont(context)),
                  ),
                ),
              ],
            ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7340),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.5,
                    vertical: padding * 0.75,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Add Card",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.bodyFont(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(String title, String action) {
    final padding = AppDimensions.padding(context);

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: AppDimensions.bodyFont(context),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (action == "Delete") {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove Card'),
                    content: Text('Remove "$title"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(
                            () => paymentMethods.removeWhere(
                              (m) => m['type'] == title,
                            ),
                          );
                          _showSnackBar('Card removed', Colors.orange);
                        },
                        child: const Text(
                          'Remove',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text(
              action,
              style: TextStyle(
                color: action == "Delete" ? Colors.red : Colors.blue,
                fontSize: AppDimensions.smallFont(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordManager() {
    final padding = AppDimensions.padding(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.grey300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Change Password",
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: padding * 1.5),
            _buildPasswordField(
              "Current Password *",
              "Enter current password",
              currentPasswordController,
            ),
            _buildPasswordField(
              "New Password *",
              "Enter new password",
              newPasswordController,
            ),
            _buildPasswordField(
              "Confirm New Password *",
              "Confirm password",
              confirmPasswordController,
            ),
            SizedBox(height: padding),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B7340),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 1.5,
                    vertical: padding * 0.75,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Update Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.bodyFont(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    final padding = AppDimensions.padding(context);

    bool isCurrentPassword = label.contains("Current");
    bool isNewPassword = label.contains("New") && !label.contains("Confirm");
    bool isConfirmPassword = label.contains("Confirm");

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppDimensions.bodyFont(context),
            ),
          ),
          SizedBox(height: padding / 2),
          TextField(
            controller: controller,
            obscureText: isCurrentPassword
                ? !showCurrentPassword
                : isNewPassword
                ? !showNewPassword
                : !showConfirmPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: AppDimensions.smallFont(context)),
              suffixIcon: IconButton(
                icon: Icon(
                  isCurrentPassword
                      ? (showCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off)
                      : isNewPassword
                      ? (showNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off)
                      : (showConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                ),
                onPressed: () {
                  setState(() {
                    if (isCurrentPassword) {
                      showCurrentPassword = !showCurrentPassword;
                    } else if (isNewPassword) {
                      showNewPassword = !showNewPassword;
                    } else if (isConfirmPassword) {
                      showConfirmPassword = !showConfirmPassword;
                    }
                  });
                },
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(
    String label,
    String hint, {
    TextEditingController? controller,
    bool enabled = true,
  }) {
    final padding = AppDimensions.padding(context);

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppDimensions.bodyFont(context),
            ),
          ),
          SizedBox(height: padding / 2),
          TextField(
            controller: controller,
            readOnly: !enabled,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: AppDimensions.smallFont(context)),
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              filled: !enabled,
              fillColor: !enabled ? Colors.black12 : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.grey300, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogout() {
    final padding = AppDimensions.padding(context);
    final r = AppResponsive.of(context);
    final isMobile = r.isSmallMobile || r.isMobile;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius(context)),
        side: BorderSide(color: AppColors.grey300, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * (isMobile ? 1.25 : 2)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              size: _logoutIconSize(context),
              color: AppColors.grey300,
            ),
            SizedBox(height: padding),
            Text(
              "Are you sure you want to logout?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grey300,
                fontSize: AppDimensions.bodyFont(context),
              ),
            ),
            SizedBox(height: padding * 1.5),
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedMenu = "Personal Information";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black12,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 1.25,
                            vertical: padding * 0.75,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _radius(context),
                            ),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppDimensions.bodyFont(context),
                          ),
                        ),
                      ),
                      SizedBox(height: padding),
                      ElevatedButton(
                        onPressed: () async {
                          await ApiService.clearToken();
                          await AuthSession.clear();
                          if (mounted) {
                            context.read<OrdersProvider>().clearForLogout();
                            await context.read<CartProvider>().switchToGuest();
                            context.read<WishlistProvider>().clearWishlist();
                          }
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const Signup(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 1.25,
                            vertical: padding * 0.75,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _radius(context),
                            ),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppDimensions.bodyFont(context),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedMenu = "Personal Information";
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.grey300,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 1.5,
                            vertical: padding * 0.75,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _radius(context),
                            ),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: AppDimensions.bodyFont(context),
                          ),
                        ),
                      ),
                      SizedBox(width: padding),
                      ElevatedButton(
                        onPressed: () async {
                          await ApiService.clearToken();
                          await AuthSession.clear();
                          if (mounted) {
                            context.read<OrdersProvider>().clearForLogout();
                            await context.read<CartProvider>().switchToGuest();
                            context.read<WishlistProvider>().clearWishlist();
                          }
                          if (!mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const Signup(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                            horizontal: padding * 1.5,
                            vertical: padding * 0.75,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              _radius(context),
                            ),
                          ),
                        ),
                        child: Text(
                          "Logout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppDimensions.bodyFont(context),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint, {
    bool isDropdown = false,
    TextEditingController? controller,
  }) {
    final padding = AppDimensions.padding(context);

    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppDimensions.bodyFont(context),
            ),
          ),
          SizedBox(height: padding / 2),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: isDropdown
                  ? Icon(Icons.keyboard_arrow_down, size: _icon(context))
                  : null,
              contentPadding: EdgeInsets.symmetric(
                horizontal: padding,
                vertical: padding * 0.75,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _radius(context, factor: 0.8),
                ),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _radius(context, factor: 0.8),
                ),
                borderSide: BorderSide(color: AppColors.grey300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  _radius(context, factor: 0.8),
                ),
                borderSide: BorderSide(color: AppColors.grey300, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update Methods
  Future<void> _updatePersonalInfo() async {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() {
      isEditingPersonalInfo = false;
    });

    final primaryAddress = addresses.isNotEmpty
        ? (addresses.first['address'] ?? '')
        : '';
    final userData = UserData(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      gender: selectedGender,
      address: primaryAddress,
    );
    await AuthSession.updateUserData(userData);

    try {
      await ApiService.updateProfile({
        'firstName': userData.firstName,
        'lastName': userData.lastName,
        'phone': userData.phone,
        'address': primaryAddress,
        'gender': userData.gender,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully! (Saved to database)"),
          backgroundColor: Colors.green,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Profile saved locally. DB update failed: ${e.message}",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Profile saved locally. Start backend to sync to database.",
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _addAddress() async {
    if (streetAddressController.text.isEmpty) {
      _showSnackBar("Please enter Street Address", Colors.red);
      return;
    }

    final parts = <String>[];
    final street = streetAddressController.text.trim();
    final building = buildingAddressController.text.trim();
    final city = cityController.text.trim();
    final zip = zipCodeController.text.trim();
    if (street.isNotEmpty) parts.add(street);
    if (building.isNotEmpty) parts.add(building);
    if (city.isNotEmpty) parts.add(city);
    final addressText = parts.join(', ') + (zip.isNotEmpty ? ' $zip' : '');

    setState(() {
      addresses.add({"address": addressText});
    });

    streetAddressController.clear();
    buildingAddressController.clear();
    cityController.clear();
    zipCodeController.clear();

    final userData = await AuthSession.getUserData();
    final updated = userData != null
        ? UserData(
            firstName: userData.firstName,
            lastName: userData.lastName,
            email: userData.email,
            phone: userData.phone,
            gender: userData.gender,
            address: addressText,
          )
        : null;
    if (updated != null) await AuthSession.updateUserData(updated);
    try {
      await ApiService.updateProfile({'address': addressText});
    } catch (e) {
      if (mounted)
        _showSnackBar(
          'Address saved locally. Sync failed: ${e.toString()}',
          Colors.orange,
        );
      return;
    }

    if (mounted)
      _showSnackBar("Address added and saved to profile!", Colors.green);
  }

  Future<void> _deleteAddress(int index) async {
    if (index < 0 || index >= addresses.length) return;
    setState(() => addresses.removeAt(index));
    final primaryAddress = addresses.isNotEmpty
        ? (addresses.first['address'] ?? '')
        : '';
    final userData = await AuthSession.getUserData();
    if (userData != null) {
      final updated = UserData(
        firstName: userData.firstName,
        lastName: userData.lastName,
        email: userData.email,
        phone: userData.phone,
        gender: userData.gender,
        address: primaryAddress,
      );
      await AuthSession.updateUserData(updated);
    }
    try {
      await ApiService.updateProfile({'address': primaryAddress});
    } catch (e) {
      if (mounted)
        _showSnackBar(
          'Address deleted locally. Sync failed: ${e.toString()}',
          Colors.orange,
        );
      return;
    }
    if (mounted) _showSnackBar("Address deleted", Colors.orange);
  }

  void _addPaymentMethod() {
    if (cardNumberController.text.isEmpty ||
        expiryDateController.text.isEmpty) {
      _showSnackBar("Please fill all required fields", Colors.red);
      return;
    }

    setState(() {
      paymentMethods.add({
        "type":
            "${cardHolderController.text} ???? ${cardNumberController.text.substring(cardNumberController.text.length - 4)}",
        "status": "Active",
      });
    });

    cardHolderController.clear();
    cardNumberController.clear();
    expiryDateController.clear();
    cvvController.clear();
    setState(() {
      saveCardForFuture = false;
    });

    _showSnackBar("Card added successfully!", Colors.green);
  }

  Future<void> _updatePassword() async {
    if (currentPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnackBar("Please fill all password fields", Colors.red);
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showSnackBar("New passwords do not match!", Colors.red);
      return;
    }

    if (newPasswordController.text.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.red);
      return;
    }

    try {
      await ApiService.changePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
      );
      if (!mounted) return;
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _showSnackBar(
        "Password updated successfully! (Saved to database)",
        Colors.green,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, Colors.red);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar("Could not update password. Check backend.", Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}





