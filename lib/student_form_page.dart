import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_service.dart';
import 'dart:async';

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

class _StudentFormPageState extends State<StudentFormPage> {
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
  final TextEditingController alamatOrangTuaController = TextEditingController();
  bool isLoading = false;
  bool isDusunLoading = true;
  String? dusunError;
  List<String> dusunSuggestions = [];
  Map<String, Map<String, String>> dusunData = {};
  final List<String> agamaOptions = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu', 'Lainnya'];
  final List<String> jenisKelaminOptions = ['Laki-laki', 'Perempuan'];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchDusunFromSupabase();
    print('Initial dusunSuggestions: $dusunSuggestions'); // Debug initial state
    if (widget.existingData != null) {
      _fillExistingData();
    }
  }

  void _fillExistingData() {
    final data = widget.existingData!;
    nameController.text = data['name'] ?? '';
    nisnController.text = data['nisn'] ?? '';
    desaController.text = data['desa'] ?? '';
    selectedAgama = data['agama'];
    selectedJenisKelamin = data['jenis_kelamin'];
    tempatLahirController.text = data['tempat_lahir'] ?? '';
    tanggalLahirController.text = data['tanggal_lahir'] ?? '';
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
    alamatOrangTuaController.text = data['alamat_orang_tua'] ?? '';
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
      final response = await studentService.supabase
          .from('locations')
          .select('dusun, desa, kecamatan, kabupaten, provinsi, kode_pos')
          .order('dusun', ascending: true);
      print('Supabase Response: $response'); // Log respons lengkap
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
        final desa = item['desa'] as String? ?? '';
        final kecamatan = item['kecamatan'] as String? ?? '';
        if (dusun.isNotEmpty) {
          final key = dusun; // Gunakan dusun sebagai kunci utama
          dusunSuggestions.add(key);
          dusunData[key] = {
            'dusun': dusun,
            'desa': desa,
            'kecamatan': kecamatan,
            'kabupaten': item['kabupaten'] as String? ?? '',
            'provinsi': item['provinsi'] as String? ?? '',
            'kode_pos': item['kode_pos'] as String? ?? '',
          };
          print('Added Dusun: $key, Full Data: ${dusunData[key]}'); // Log setiap dusun
        }
      }
      setState(() {
        isDusunLoading = false;
      });
    } catch (e) {
      print('Error fetching dusun: $e'); // Log error
      setState(() {
        dusunError = 'Gagal memuat data dusun: $e';
        isDusunLoading = false;
      });
    }
  }

  void _autoFillAddress(String key) {
    final data = dusunData[key];
    if (data != null) {
      setState(() {
        dusunController.text = data['dusun'] ?? '';
        desaController.text = data['desa'] ?? '';
        kecamatanController.text = data['kecamatan'] ?? '';
        kabupatenController.text = data['kabupaten'] ?? '';
        provinsiController.text = data['provinsi'] ?? '';
        kodePosController.text = data['kode_pos'] ?? '';
      });
    } else {
      print('Data for key "$key" not found in dusunData');
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
    alamatOrangTuaController.dispose();
    super.dispose();
  }

  Future<bool?> _showConfirmationDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: widget.primaryDarkBlue)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Konfirmasi'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        );
      },
    );
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.existingData != null;
    final action = isEdit ? 'memperbarui' : 'menambahkan';
    final name = nameController.text.trim();
    final confirm = await _showConfirmationDialog(
      isEdit ? 'Konfirmasi Perubahan' : 'Konfirmasi Penyimpanan',
      'Apakah Anda yakin ingin $action data siswa "$name"?',
    );
    if (confirm != true) return;
    setState(() => isLoading = true);
    final studentData = {
      'name': nameController.text.trim(),
      'nisn': nisnController.text.trim(),
      'desa': desaController.text.trim(),
      'agama': selectedAgama,
      'jenis_kelamin': selectedJenisKelamin,
      'tempat_lahir': tempatLahirController.text.trim(),
      'tanggal_lahir': tanggalLahirController.text.trim(),
      'no_telepon': noTeleponController.text.trim(),
      'nik': nikController.text.trim(),
      'dusun': dusunController.text.trim(),
      'kecamatan': kecamatanController.text.trim(),
      'rt_rw': rtRwController.text.trim(),
      'jalan': jalanController.text.trim(),
      'kabupaten': kabupatenController.text.trim(),
      'provinsi': provinsiController.text.trim(),
      'kode_pos': kodePosController.text.trim(),
      'nama_ayah': namaAyahController.text.trim(),
      'nama_ibu': namaIbuController.text.trim(),
      'nama_wali': namaWaliController.text.trim(),
      'alamat_orang_tua': alamatOrangTuaController.text.trim(),
    };
    try {
      if (isEdit) {
        final id = widget.existingData!['id'] ?? widget.existingData!['nisn'];
        await studentService.updateStudent(id, studentData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data siswa berhasil diperbarui')));
      } else {
        await studentService.addStudent(studentData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data siswa berhasil ditambahkan')));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
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
        validator: validator ?? (value) => value == null || value.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
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
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        validator: validator ?? (value) => value == null ? '$label wajib diisi' : null,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildAutocompleteDusun() {
    if (isDusunLoading) return const Center(child: CircularProgressIndicator());
    if (dusunError != null) return Text(dusunError!, style: const TextStyle(color: Colors.red));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          print('Text input: ${textEditingValue.text}, Suggestions: $dusunSuggestions'); // Debug
          if (textEditingValue.text.isEmpty) {
            return dusunSuggestions;
          }
          return dusunSuggestions.where((option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          }).toList();
        },
        onSelected: (selection) {
          _autoFillAddress(selection);
        },
        fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
          fieldController.text = dusunController.text;
          return TextFormField(
            controller: fieldController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Dusun',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Dusun wajib diisi';
              if (!dusunData.containsKey(value)) return 'Dusun tidak ditemukan';
              return null;
            },
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                setState(() {
                  dusunController.text = value;
                  if (dusunData.containsKey(value)) {
                    _autoFillAddress(value);
                  }
                });
              });
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: SizedBox(
                height: 200.0,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return GestureDetector(
                      onTap: () => onSelected(option),
                      child: ListTile(
                        title: Text(option, style: const TextStyle(fontSize: 14)),
                      ),
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
      appBar: AppBar(
        backgroundColor: widget.primaryDarkBlue,
        title: Text(isEdit ? 'Edit Data Siswa' : 'Tambah Siswa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Pribadi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(label: 'Nama Lengkap', controller: nameController),
                        _buildTextField(
                          label: 'NISN',
                          controller: nisnController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'NISN wajib diisi';
                            if (value.length != 10) return 'NISN harus 10 karakter';
                            return null;
                          },
                        ),
                        _buildDropdownField(
                          label: 'Agama',
                          value: selectedAgama,
                          items: agamaOptions,
                          onChanged: (v) => setState(() => selectedAgama = v),
                        ),
                        _buildDropdownField(
                          label: 'Jenis Kelamin',
                          value: selectedJenisKelamin,
                          items: jenisKelaminOptions,
                          onChanged: (v) => setState(() => selectedJenisKelamin = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(label: 'Tempat Lahir', controller: tempatLahirController),
                        _buildTextField(
                          label: 'Tanggal Lahir (YYYY-MM-DD)',
                          controller: tanggalLahirController,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Tanggal lahir wajib diisi';
                            final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                            if (!regex.hasMatch(value)) return 'Format: YYYY-MM-DD';
                            return null;
                          },
                        ),
                        _buildTextField(label: 'No Telepon', controller: noTeleponController, keyboardType: TextInputType.phone),
                        _buildTextField(
                          label: 'NIK',
                          controller: nikController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'NIK wajib diisi';
                            if (value.length != 16) return 'NIK harus 16 digit';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Data Alamat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildAutocompleteDusun(),
                        _buildTextField(label: 'Kecamatan', controller: kecamatanController),
                        _buildTextField(label: 'RT/RW', controller: rtRwController, keyboardType: TextInputType.text),
                        _buildTextField(label: 'Jalan', controller: jalanController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(label: 'Kabupaten', controller: kabupatenController),
                        _buildTextField(label: 'Provinsi', controller: provinsiController),
                        _buildTextField(
                          label: 'Kode Pos',
                          controller: kodePosController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Kode pos wajib diisi';
                            if (!RegExp(r'^\d{5}$').hasMatch(value)) return 'Kode pos harus 5 digit';
                            return null;
                          },
                        ),
                        _buildTextField(label: 'Desa', controller: desaController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Data Orang Tua/Wali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(label: 'Nama Ayah', controller: namaAyahController),
                        _buildTextField(label: 'Nama Ibu', controller: namaIbuController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField(label: 'Nama Wali', controller: namaWaliController),
                        _buildTextField(label: 'Alamat Orang Tua', controller: alamatOrangTuaController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _saveStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryDarkBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEdit ? 'Update' : 'Simpan', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}