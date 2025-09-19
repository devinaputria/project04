// File: student_form_page.dart (Fixed intl package import, added null checks, improved date picker)
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_service.dart';
import 'dart:async';
import 'review_page.dart';
import 'package:intl/intl.dart';

class StudentFormPage extends StatefulWidget {
  final Color primaryDarkBlue;
  final Map<String, dynamic>? existingData;

  const StudentFormPage({
    super.key,
    required this.primaryDarkBlue,
    this.existingData,
  });

  @override
  State<StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<StudentFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final StudentService studentService = StudentService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController desaController = TextEditingController();
  String? selectedAgama;
  String? selectedJenisKelamin;
  final TextEditingController tempatLahirController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();
  final TextEditingController noTeleponController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController dusunController = TextEditingController();
  final TextEditingController kecamatanController = TextEditingController();
  final TextEditingController rtRwController = TextEditingController();
  final TextEditingController jalanController = TextEditingController();
  final TextEditingController kabupatenController = TextEditingController();
  final TextEditingController provinsiController = TextEditingController();
  final TextEditingController kodePosController = TextEditingController();
  final TextEditingController namaAyahController = TextEditingController();
  final TextEditingController namaIbuController = TextEditingController();
  final TextEditingController namaWaliController = TextEditingController();
  final TextEditingController alamatOrtuController = TextEditingController();
  bool isLoading = false;
  bool isDusunLoading = true;
  String? dusunError;
  List<String> dusunSuggestions = [];
  Map<String, Map<String, String>> dusunData = {};
  final List<String> agamaOptions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
    'Lainnya',
  ];
  final List<String> jenisKelaminOptions = ['Laki-laki', 'Perempuan'];
  Timer? _debounce;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    print('existingData: ${widget.existingData}');
    _fetchDusunFromSupabase();
    if (widget.existingData != null) {
      _fillExistingData();
    }
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() => _opacity = 1.0);
    });
  }

  void _fillExistingData() {
    final data = widget.existingData!;
    nameController.text = data['name'] ?? '';
    nisnController.text = data['nisn'] ?? '';
    desaController.text = data['desa'] ?? '';
    selectedAgama = data['agama'];
    selectedJenisKelamin = data['jenis_kelamin'];
    tempatLahirController.text = data['tempat_lahir'] ?? '';
    tanggalLahirController.text = data['tanggal_lahir'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(data['tanggal_lahir']))
        : '';
    noTeleponController.text = data['no_telepon'] ?? '';
    nikController.text = data['nik'] ?? '';
    dusunController.text = data['dusun'] ?? '';
    kecamatanController.text = data['kecamatan'] ?? '';
    rtRwController.text = data['rt_rw'] ?? '';
    jalanController.text = data['jalan'] ?? '';
    kabupatenController.text = data['kabupaten'] ?? '';
    provinsiController.text = data['provinsi'] ?? '';
    kodePosController.text = data['kode_pos'] ?? '';
    namaAyahController.text = data['nama_ayah'] ?? '';
    namaIbuController.text = data['nama_ibu'] ?? '';
    namaWaliController.text = data['nama_wali'] ?? '';
    alamatOrtuController.text = data['alamat_orang_tua'] ?? '';
    if (dusunData.containsKey(dusunController.text)) {
      _autoFillAddress(dusunController.text);
    }
  }

  Future<void> _fetchDusunFromSupabase() async {
    setState(() {
      isDusunLoading = true;
      dusunError = null;
    });
    try {
      final isConnected = await studentService.checkInternetConnection();
      if (!isConnected) {
        throw Exception(
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
        );
      }
      final response = await studentService.supabase
          .from('locations')
          .select('dusun, desa, kecamatan, kabupaten, provinsi, kode_pos')
          .order('dusun', ascending: true);
      if (response.isEmpty) {
        setState(() {
          dusunError = 'Data dusun kosong';
          isDusunLoading = false;
        });
        return;
      }
      dusunData = {};
      dusunSuggestions = [];
      for (var item in response) {
        final dusun = item['dusun'] as String? ?? '';
        if (dusun.isNotEmpty) {
          final key = dusun;
          dusunSuggestions.add(key);
          dusunData[key] = {
            'dusun': dusun,
            'desa': item['desa'] as String? ?? '',
            'kecamatan': item['kecamatan'] as String? ?? '',
            'kabupaten': item['kabupaten'] as String? ?? '',
            'provinsi': item['provinsi'] as String? ?? '',
            'kode_pos': item['kode_pos'] as String? ?? '',
          };
        }
      }
      setState(() {
        isDusunLoading = false;
      });
    } catch (e) {
      setState(() {
        dusunError = e.toString().contains('Tidak ada koneksi internet')
            ? 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.'
            : 'Gagal Terjadi Kesalahan pada Supabase anda tolong cek internet anda dulu';
        isDusunLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dusunError!),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: _fetchDusunFromSupabase,
          ),
        ),
      );
    }
  }

  void _autoFillAddress(String key) {
    final data = dusunData[key];
    if (data != null) {
      setState(() {
        desaController.text = data['desa'] ?? '';
        kecamatanController.text = data['kecamatan'] ?? '';
        kabupatenController.text = data['kabupaten'] ?? '';
        provinsiController.text = data['provinsi'] ?? '';
        kodePosController.text = data['kode_pos'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    nameController.dispose();
    nisnController.dispose();
    desaController.dispose();
    tempatLahirController.dispose();
    tanggalLahirController.dispose();
    noTeleponController.dispose();
    nikController.dispose();
    dusunController.dispose();
    kecamatanController.dispose();
    rtRwController.dispose();
    jalanController.dispose();
    kabupatenController.dispose();
    provinsiController.dispose();
    kodePosController.dispose();
    namaAyahController.dispose();
    namaIbuController.dispose();
    namaWaliController.dispose();
    alamatOrtuController.dispose();
    super.dispose();
  }

  Future<void> _proceedToReview() async {
    if (!_formKey.currentState!.validate()) return;

    final isConnected = await studentService.checkInternetConnection();
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: _proceedToReview,
          ),
        ),
      );
      return;
    }

    final data = {
      'nisn': nisnController.text.trim(),
      'name': nameController.text.trim(),
      'jenis_kelamin': selectedJenisKelamin ?? '',
      'agama': selectedAgama ?? '',
      'tempat_lahir': tempatLahirController.text.trim(),
      'tanggal_lahir': tanggalLahirController.text.trim(),
      'no_telepon': noTeleponController.text.trim(),
      'nik': nikController.text.trim(),
      'desa': desaController.text.trim(),
      'dusun': dusunController.text.trim(),
      'kecamatan': kecamatanController.text.trim(),
      'kabupaten': kabupatenController.text.trim(),
      'provinsi': provinsiController.text.trim(),
      'kode_pos': kodePosController.text.trim(),
      'jalan': jalanController.text.trim(),
      'rt_rw': rtRwController.text.trim(),
      'nama_ayah': namaAyahController.text.trim(),
      'nama_ibu': namaIbuController.text.trim(),
      'nama_wali': namaWaliController.text.trim(),
      'alamat_orang_tua': alamatOrtuController.text.trim(),
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          primaryDarkBlue: widget.primaryDarkBlue,
          nisn: data['nisn'] as String,
          name: data['name'] as String,
          jenisKelamin: data['jenis_kelamin'] as String,
          agama: data['agama'] as String,
          tempatTanggalLahir:
              '${data['tempat_lahir']}, ${data['tanggal_lahir']}',
          noTelepon: data['no_telepon'] as String,
          nik: data['nik'] as String,
          alamat: {
            'jalan': data['jalan'],
            'rt_rw': data['rt_rw'],
            'dusun': data['dusun'],
            'desa': data['desa'],
            'kecamatan': data['kecamatan'],
            'kabupaten': data['kabupaten'],
            'provinsi': data['provinsi'],
            'kode_pos': data['kode_pos'],
          },
          namaAyah: data['nama_ayah'] as String,
          namaIbu: data['nama_ibu'] as String,
          namaWali: data['nama_wali'] as String?,
          alamatOrtu: data['alamat_orang_tua'] as String,
          isEditMode: widget.existingData != null,
        ),
      ),
    );
    if (result != null) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryDarkBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: widget.primaryDarkBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: children,
        initiallyExpanded: true,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        enabled: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: widget.primaryDarkBlue)
              : null,
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: widget.primaryDarkBlue)
              : null,
          labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildAutocompleteDusun() {
    if (isDusunLoading) return const Center(child: CircularProgressIndicator());
    if (dusunError != null)
      return Column(
        children: [
          Text(dusunError!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _fetchDusunFromSupabase,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.primaryDarkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          final input = textEditingValue.text.toLowerCase();
          return dusunSuggestions
              .where((option) => option.toLowerCase().contains(input))
              .toList();
        },
        onSelected: (selection) {
          setState(() {
            dusunController.text = selection;
            _autoFillAddress(selection);
          });
        },
        fieldViewBuilder:
            (context, fieldController, focusNode, onFieldSubmitted) {
              fieldController.text = dusunController.text;
              return TextFormField(
                controller: fieldController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Dusun',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: widget.primaryDarkBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.primaryDarkBlue,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Dusun wajib diisi';
                  if (!dusunData.containsKey(value))
                    return 'Dusun tidak ditemukan';
                  return null;
                },
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => dusunController.text = value);
                    if (dusunData.containsKey(value)) _autoFillAddress(value);
                  });
                },
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingData != null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEdit ? 'Edit Data Siswa' : 'Tambah Siswa',
          style: const TextStyle(color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.primaryDarkBlue, Colors.blue[800]!],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(seconds: 1),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Data Pribadi', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Nama Lengkap',
                            controller: nameController,
                            icon: Icons.person,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nama lengkap wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'NISN',
                            controller: nisnController,
                            icon: Icons.badge,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.length != 10
                                ? 'NISN harus 10 karakter'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Jenis Kelamin',
                            value: selectedJenisKelamin,
                            items: jenisKelaminOptions,
                            onChanged: (v) =>
                                setState(() => selectedJenisKelamin = v),
                            icon: Icons.transgender,
                            validator: (v) => v == null
                                ? 'Jenis kelamin wajib dipilih'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Agama',
                            value: selectedAgama,
                            items: agamaOptions,
                            onChanged: (v) => setState(() => selectedAgama = v),
                            icon: Icons.church,
                            validator: (v) =>
                                v == null ? 'Agama wajib dipilih' : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Tempat Lahir',
                            controller: tempatLahirController,
                            icon: Icons.place,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Tempat lahir wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Tanggal Lahir',
                            controller: tanggalLahirController,
                            icon: Icons.calendar_today,
                            readOnly: true,
                            onTap: _pickDate,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Tanggal lahir wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'No Telp/HP',
                            controller: noTeleponController,
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'No telp wajib diisi';
                              if (v.length < 12 ||
                                  v.length > 15 ||
                                  !RegExp(r'^\d+$').hasMatch(v))
                                return 'No telp 12-15 digit angka';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'NIK',
                            controller: nikController,
                            icon: Icons.card_membership,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.length != 16
                                ? 'NIK harus 16 digit'
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  _buildSection('Alamat', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Jalan',
                            controller: jalanController,
                            icon: Icons.streetview,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Jalan wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'RT/RW',
                            controller: rtRwController,
                            icon: Icons.home_work,
                            validator: (v) =>
                                v == null ||
                                    v.isEmpty ||
                                    !RegExp(r'^\d{3}/\d{3}$').hasMatch(v)
                                ? 'RT/RW wajib diisi (format 001/002)'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    _buildAutocompleteDusun(),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Desa',
                            controller: desaController,
                            icon: Icons.home,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Kecamatan',
                            controller: kecamatanController,
                            icon: Icons.location_city,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Kabupaten',
                            controller: kabupatenController,
                            icon: Icons.map,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Provinsi',
                            controller: provinsiController,
                            icon: Icons.public,
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      label: 'Kode Pos',
                      controller: kodePosController,
                      icon: Icons.local_post_office,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.length != 5
                          ? 'Kode pos harus 5 digit'
                          : null,
                    ),
                  ]),
                  _buildSection('Orang Tua / Wali', [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Nama Ayah',
                            controller: namaAyahController,
                            icon: Icons.man,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nama ayah wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Nama Ibu',
                            controller: namaIbuController,
                            icon: Icons.woman,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Nama ibu wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Nama Wali (opsional)',
                            controller: namaWaliController,
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Alamat Orang Tua/Wali',
                            controller: alamatOrtuController,
                            icon: Icons.home,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _proceedToReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryDarkBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 10,
                        shadowColor: Colors.black.withOpacity(0.5),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'Update' : 'Review & Simpan',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
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
