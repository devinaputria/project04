import 'package:flutter/material.dart';
import 'student_service.dart';

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

  final List<String> agamaOptions = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu', 'Lainnya'];
  final List<String> jenisKelaminOptions = ['Laki-laki', 'Perempuan'];

  // Daftar data dusun dengan informasi terkait
  final Map<String, Map<String, String>> dusunData = {
    'Dusun 1': {
      'desa': 'Desa Sukamaju',
      'kecamatan': 'Kecamatan Sukasari',
      'kabupaten': 'Kabupaten Bandung',
      'provinsi': 'Jawa Barat',
      'kode_pos': '40123',
    },
    'Dusun 2': {
      'desa': 'Desa Cikupa',
      'kecamatan': 'Kecamatan Cianjur',
      'kabupaten': 'Kabupaten Cianjur',
      'provinsi': 'Jawa Barat',
      'kode_pos': '43210',
    },
    'Dusun 3': {
      'desa': 'Desa Pagedangan',
      'kecamatan': 'Kecamatan Tangerang',
      'kabupaten': 'Kabupaten Tangerang',
      'provinsi': 'Banten',
      'kode_pos': '15321',
    },
    // Tambahkan lebih banyak data sesuai kebutuhan
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      nameController.text = widget.existingData!['name'] ?? '';
      nisnController.text = widget.existingData!['nisn'] ?? '';
      desaController.text = widget.existingData!['desa'] ?? '';
      selectedAgama = widget.existingData!['agama'] ?? '';
      selectedJenisKelamin = widget.existingData!['jenis_kelamin'] ?? '';
      tempatLahirController.text = widget.existingData!['tempat_lahir'] ?? '';
      tanggalLahirController.text = widget.existingData!['tanggal_lahir'] ?? '';
      noTeleponController.text = widget.existingData!['no_telepon'] ?? '';
      nikController.text = widget.existingData!['nik'] ?? '';
      dusunController.text = widget.existingData!['dusun'] ?? '';
      kecamatanController.text = widget.existingData!['kecamatan'] ?? '';
      rtRwController.text = widget.existingData!['rt_rw'] ?? '';
      jalanController.text = widget.existingData!['jalan'] ?? '';
      kabupatenController.text = widget.existingData!['kabupaten'] ?? '';
      provinsiController.text = widget.existingData!['provinsi'] ?? '';
      kodePosController.text = widget.existingData!['kode_pos'] ?? '';
      namaAyahController.text = widget.existingData!['nama_ayah'] ?? '';
      namaIbuController.text = widget.existingData!['nama_ibu'] ?? '';
      namaWaliController.text = widget.existingData!['nama_wali'] ?? '';
      alamatOrangTuaController.text = widget.existingData!['alamat_orang_tua'] ?? '';

      // Isi otomatis jika dusun ada di data
      if (dusunData.containsKey(dusunController.text)) {
        final data = dusunData[dusunController.text]!;
        desaController.text = data['desa'] ?? '';
        kecamatanController.text = data['kecamatan'] ?? '';
        kabupatenController.text = data['kabupaten'] ?? '';
        provinsiController.text = data['provinsi'] ?? '';
        kodePosController.text = data['kode_pos'] ?? '';
      }
    }
  }

  @override
  void dispose() {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final isEdit = widget.existingData != null;
      final action = isEdit ? 'memperbarui' : 'menambahkan';
      final name = nameController.text.trim();

      final confirm = await _showConfirmationDialog(
        isEdit ? 'Konfirmasi Perubahan' : 'Konfirmasi Penyimpanan',
        'Apakah Anda yakin ingin ${action} data siswa "$name"?',
      );

      if (confirm != true) return;

      setState(() {
        isLoading = true;
      });

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
        if (widget.existingData == null) {
          await studentService.addStudent(studentData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data siswa berhasil ditambahkan')),
            );
          }
        } else {
          final id = widget.existingData!['id'] ?? widget.existingData!['nisn'];
          await studentService.updateStudent(id, studentData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data siswa berhasil diperbarui')),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: const BorderSide(color: Colors.grey, width: 1.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        items: items.map<DropdownMenuItem<String>>((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildAutocompleteDusun() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return dusunData.keys.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          setState(() {
            dusunController.text = selection;
            final data = dusunData[selection]!;
            desaController.text = data['desa'] ?? '';
            kecamatanController.text = data['kecamatan'] ?? '';
            kabupatenController.text = data['kabupaten'] ?? '';
            provinsiController.text = data['provinsi'] ?? '';
            kodePosController.text = data['kode_pos'] ?? '';
          });
        },
        fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
          return TextFormField(
            controller: fieldController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Dusun',
              labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(color: widget.primaryDarkBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.red, width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) => value == null || value.isEmpty ? 'Dusun wajib diisi' : null,
            onFieldSubmitted: (value) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
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
      appBar: AppBar(
        backgroundColor: widget.primaryDarkBlue,
        title: Text(
          isEdit ? 'Edit Data Siswa' : 'Tambah Siswa',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Pribadi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Nama Lengkap',
                              controller: nameController,
                            ),
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
                            _buildTextField(label: 'Desa', controller: desaController),
                            _buildDropdownField(
                              label: 'Agama',
                              value: selectedAgama,
                              items: agamaOptions,
                              onChanged: (value) => setState(() => selectedAgama = value),
                              validator: (value) => value == null ? 'Agama wajib dipilih' : null,
                            ),
                            _buildDropdownField(
                              label: 'Jenis Kelamin',
                              value: selectedJenisKelamin,
                              items: jenisKelaminOptions,
                              onChanged: (value) => setState(() => selectedJenisKelamin = value),
                              validator: (value) => value == null ? 'Jenis Kelamin wajib dipilih' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Tempat Lahir',
                              controller: tempatLahirController,
                            ),
                            _buildTextField(
                              label: 'Tanggal Lahir',
                              controller: tanggalLahirController,
                            ),
                            _buildTextField(
                              label: 'No Telepon',
                              controller: noTeleponController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'No Telepon wajib diisi';
                                if (value.length < 12 || value.length > 15) return 'No Telepon harus 12-15 karakter';
                                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'No Telepon hanya boleh angka';
                                return null;
                              },
                            ),
                            _buildTextField(
                              label: 'NIK',
                              controller: nikController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'NIK wajib diisi';
                                if (value.length != 16) return 'NIK harus 16 karakter';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Data Alamat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAutocompleteDusun(),
                            _buildTextField(label: 'Kecamatan', controller: kecamatanController),
                            _buildTextField(
                              label: 'RT/RW',
                              controller: rtRwController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'RT/RW wajib diisi';
                                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'RT/RW hanya boleh angka';
                                return null;
                              },
                            ),
                            _buildTextField(
                              label: 'Jalan',
                              controller: jalanController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(label: 'Kabupaten', controller: kabupatenController),
                            _buildTextField(label: 'Provinsi', controller: provinsiController),
                            _buildTextField(
                              label: 'Kode Pos',
                              controller: kodePosController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Data Orang Tua/Wali',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.primaryDarkBlue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField(
                              label: 'Nama Ayah',
                              controller: namaAyahController,
                            ),
                            _buildTextField(
                              label: 'Nama Ibu',
                              controller: namaIbuController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryDarkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: const BorderSide(color: Colors.white, width: 1.0),
                          ),
                        ),
                        onPressed: isLoading ? null : _saveStudent,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                isEdit ? 'Update' : 'Simpan',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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