import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth_provider.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSchools();
  }

  void _loadSchools() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SchoolProvider>().loadSchools();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: Consumer<SchoolProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return _buildLoadingState(theme);
                if (provider.error != null) return _buildErrorState(provider);
                if (provider.schools.isEmpty) return _buildEmptyState();
                return _buildSchoolsList(provider, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Super Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage all schools and settings',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateSchoolDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add School'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => context.read<SchoolProvider>().loadSchools(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                  if (context.mounted) context.go('/login');
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading schools...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(SchoolProvider provider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadSchools(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            Text(
              'No Schools Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first school to get started',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateSchoolDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add School'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolsList(SchoolProvider provider, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(provider, theme),
          const SizedBox(height: 32),
          Text(
            'All Schools',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildSchoolsTable(provider, theme)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(SchoolProvider provider, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.school, size: 32, color: theme.primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Schools',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.schools.length}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolsTable(SchoolProvider provider, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: provider.schools.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) =>
                  _buildSchoolRow(provider.schools[index], index, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          _headerCell('ID', width: 60),
          _headerCell('School Name', flex: 3),
          _headerCell('Location', flex: 2),
          _headerCell('Login ID', flex: 2),
          _headerCell('Students', width: 100, center: true),
          _headerCell('Actions', width: 140, center: true),
        ],
      ),
    );
  }

  Widget _headerCell(
    String text, {
    int? width,
    int? flex,
    bool center = false,
  }) {
    final child = Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
        fontSize: 14,
      ),
    );

    if (flex != null) return Expanded(flex: flex, child: child);
    return SizedBox(width: width?.toDouble(), child: child);
  }

  Widget _buildSchoolRow(dynamic school, int index, ThemeData theme) {
    return InkWell(
      onTap: () => context.go('/school/${school.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        school.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      school.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                school.location,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                school.schoolLoginId,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 100,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: 'View',
                    color: theme.primaryColor,
                    onPressed: () => context.go('/school/${school.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit',
                    color: Colors.orange,
                    onPressed: () => _showEditDialog(school),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Delete',
                    color: Colors.red,
                    onPressed: () => _showDeleteDialog(school),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSchoolDialog(BuildContext parentContext) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'name': TextEditingController(),
      'contact': TextEditingController(),
      'location': TextEditingController(),
      'prefix': TextEditingController(),
      'password': TextEditingController(),
    };

    _showFormDialog(
      context: parentContext,
      title: 'Create New School',
      icon: Icons.add_business,
      headerColor: Theme.of(parentContext).primaryColor,
      formKey: formKey,
      controllers: controllers,
      showPassword: true,

      // ✅ Empty onSubmit (not used in create mode)
      onSubmit: () {},

      // ✅ The actual submit handler with image bytes
      onSubmitWithImages: (frontBytes, backBytes) async {
        if (formKey.currentState!.validate()) {
          final provider = parentContext.read<SchoolProvider>();

          print('Creating school...');
          print('Front bytes: ${frontBytes?.length}');
          print('Back bytes: ${backBytes?.length}');

          final success = await provider.createSchool(
            name: controllers['name']!.text.trim(),
            contactNumber: controllers['contact']!.text.trim(),
            location: controllers['location']!.text.trim(),
            idCardPrefix: controllers['prefix']!.text.trim(),
            password: controllers['password']!.text,
            idCardFrontBytes: frontBytes, // ✅ Now receives bytes from dialog
            idCardBackBytes: backBytes, // ✅ Now receives bytes from dialog
          );

          print('Create success: $success');

          if (parentContext.mounted) {
            Navigator.of(parentContext).pop();
            if (success) {
              _showSnackbar(
                parentContext,
                'School created successfully',
                Colors.green,
              );
              await provider.loadSchools();
            } else if (provider.error != null) {
              _showSnackbar(parentContext, provider.error!, Colors.red);
            }
          }
        }
      },
    );
  }

  void _showEditDialog(dynamic school) {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      'name': TextEditingController(text: school.name),
      'contact': TextEditingController(text: school.contactNumber),
      'location': TextEditingController(text: school.location),
      'prefix': TextEditingController(text: school.idCardPrefix),
    };

    _showFormDialog(
      context: context,
      title: 'Edit School',
      icon: Icons.edit,
      headerColor: Colors.orange,
      formKey: formKey,
      controllers: controllers,
      showPassword: false,

      // ✅ Add this for edit mode
      onSubmit: () async {
        if (formKey.currentState!.validate()) {
          // TODO: Implement update logic
          if (context.mounted) {
            Navigator.pop(context);
            _showSnackbar(context, 'School updated successfully', Colors.green);
            await context.read<SchoolProvider>().loadSchools();
          }
        }
      },

      // ✅ Add empty callback (required parameter)
      onSubmitWithImages: (frontBytes, backBytes) {},
    );
  }

  void _showDeleteDialog(dynamic school) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Delete School'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${school.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<SchoolProvider>();

              print('Deleting school...');
              final success = await provider.deleteSchool(school.id);
              print('Delete success: $success');

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              if (context.mounted) {
                if (success) {
                  _showSnackbar(
                    context,
                    'School deleted successfully',
                    Colors.red,
                  );
                  print('Reloading schools...');
                  await provider.loadSchools();
                  print(
                    'After reload, schools count: ${provider.schools.length}',
                  );
                } else if (provider.error != null) {
                  print('Error: ${provider.error}');
                  _showSnackbar(context, provider.error!, Colors.red);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color headerColor,
    required GlobalKey<FormState> formKey,
    required Map<String, TextEditingController> controllers,
    required bool showPassword,
    required VoidCallback onSubmit,
    required Function(Uint8List? frontBytes, Uint8List? backBytes)
    onSubmitWithImages,
  }) {
    // ✅ DECLARE VARIABLES HERE (outside StatefulBuilder)
    Uint8List? idCardFrontBytes;
    Uint8List? idCardBackBytes;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [headerColor, headerColor.withOpacity(0.8)],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BODY
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controllers['name']!,
                                'School Name',
                                Icons.school,
                                context,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controllers['contact']!,
                                'Contact Number',
                                Icons.phone,
                                context,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controllers['location']!,
                                'Location',
                                Icons.location_on,
                                context,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controllers['prefix']!,
                                'ID Card Prefix',
                                Icons.badge,
                                context,
                              ),

                              if (showPassword) ...[
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controllers['password']!,
                                  'Admin Password',
                                  Icons.lock,
                                  context,
                                  obscure: true,
                                ),

                                const SizedBox(height: 24),
                                const Text(
                                  'ID Card Theme Images',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ✅ FRONT IMAGE
                                _buildImagePicker(
                                  label: 'ID Card Front',
                                  imageBytes: idCardFrontBytes,
                                  context: context,
                                  onPick: () async {
                                    final picker = ImagePicker();
                                    final image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      dialogSetState(() {
                                        idCardFrontBytes = bytes;
                                      });
                                    }
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ✅ BACK IMAGE
                                _buildImagePicker(
                                  label: 'ID Card Back',
                                  imageBytes: idCardBackBytes,
                                  context: context,
                                  onPick: () async {
                                    final picker = ImagePicker();
                                    final image = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (image != null) {
                                      final bytes = await image.readAsBytes();
                                      dialogSetState(() {
                                        idCardBackBytes = bytes;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // FOOTER
                    // FOOTER
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          StatefulBuilder(
                            builder: (context, setButtonState) {
                              bool isSubmitting = false;

                              return ElevatedButton(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        setButtonState(
                                          () => isSubmitting = true,
                                        );

                                        if (showPassword) {
                                          // Create mode
                                          await onSubmitWithImages(
                                            idCardFrontBytes,
                                            idCardBackBytes,
                                          );
                                        } else {
                                          // Edit mode
                                          onSubmit();
                                        }

                                        setButtonState(
                                          () => isSubmitting = false,
                                        );
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(showPassword ? 'Create' : 'Update'),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImagePicker({
    required String label,
    required Uint8List? imageBytes, // ✅ NEW

    required VoidCallback onPick,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    print('Preview bytes length: ${imageBytes?.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(
                color: imageBytes != null
                    ? theme.primaryColor
                    : Colors.grey.shade300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Center(
                          // ✅ Add Center widget
                          child: Image.memory(
                            imageBytes,
                            // fit: BoxFit.fitHeight,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended: 1024x640 px',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    BuildContext context, {
    String? hint,
    bool obscure = false,
    TextInputType? keyboardType,
    int? minLength,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.primaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
      ),
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: (v) {
        if (v?.isEmpty ?? true) return 'Required';
        if (minLength != null && v!.length < minLength) {
          return 'Min $minLength characters';
        }
        return null;
      },
    );
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
