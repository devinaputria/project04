import 'package:supabase_flutter/supabase_flutter.dart';

// KOMENTAR: Service untuk menangani operasi terkait data siswa di Supabase
class StudentService {
  final SupabaseClient supabase;

  StudentService() : supabase = Supabase.instance.client;

  // KOMENTAR: Mengambil daftar dusun dari tabel locations untuk autocomplete
  Future<List<String>> getDusunOptions() async {
    try {
      final response = await supabase
          .from('locations')
          .select('dusun')
          .order('dusun', ascending: true);
      return response.map((e) => e['dusun'] as String).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat dusun: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memuat dusun: $e');
    }
  }

  // KOMENTAR: Mengambil data alamat berdasarkan dusun untuk auto-fill
  Future<List<Map<String, dynamic>>> getAddressByDusun(String dusun) async {
    try {
      final response = await supabase
          .from('locations')
          .select('desa, kecamatan, kabupaten, kode_pos')
          .eq('dusun', dusun);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat alamat: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memuat alamat: $e');
    }
  }

  // KOMENTAR: Memeriksa apakah NISN sudah ada di tabel students
  Future<bool> isNisnExists(String nisn) async {
    try {
      final response = await supabase
          .from('students')
          .select('nisn')
          .eq('nisn', nisn)
          .limit(1);
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memeriksa NISN: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memeriksa NISN: $e');
    }
  }

  // KOMENTAR: Memeriksa apakah dusun ada di tabel locations
  Future<bool> isDusunValid(String dusun) async {
    try {
      final response = await supabase
          .from('locations')
          .select('dusun')
          .eq('dusun', dusun)
          .limit(1);
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Gagal memeriksa dusun: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memeriksa dusun: $e');
    }
  }

  // KOMENTAR: Menyimpan atau memperbarui data siswa di tabel students (untuk review_page.dart)
  Future<void> saveStudent(Map<String, dynamic> data, {bool isEditMode = false}) async {
    try {
      // Validasi dusun ada di tabel locations
      if (data['dusun'] != null && data['dusun'].isNotEmpty) {
        final validDusun = await isDusunValid(data['dusun']);
        if (!validDusun) {
          throw Exception('Dusun ${data['dusun']} tidak ditemukan di tabel locations');
        }
      }

      // Validasi NISN unik untuk insert baru
      if (!isEditMode) {
        final nisnExists = await isNisnExists(data['nisn']);
        if (nisnExists) {
          throw Exception('NISN ${data['nisn']} sudah terdaftar');
        }
      }

      if (isEditMode) {
        await supabase
            .from('students')
            .update(data)
            .eq('nisn', data['nisn']);
      } else {
        await supabase
            .from('students')
            .insert(data);
      }
    } on PostgrestException catch (e) {
      throw Exception('Gagal menyimpan data: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error menyimpan data: $e');
    }
  }

  // KOMENTAR: Menambahkan data siswa baru (untuk student_form_page.dart)
  Future<void> addStudent(Map<String, dynamic> data) async {
    try {
      // Validasi NISN unik
      final nisnExists = await isNisnExists(data['nisn']);
      if (nisnExists) {
        throw Exception('NISN ${data['nisn']} sudah terdaftar');
      }

      await supabase.from('students').insert(data);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menambah data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error menambah data siswa: $e');
    }
  }

  // KOMENTAR: Memperbarui data siswa berdasarkan ID (untuk student_form_page.dart)
  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      await supabase.from('students').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memperbarui data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memperbarui data siswa: $e');
    }
  }

  // KOMENTAR: Mengambil daftar semua siswa dari tabel students
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error memuat data siswa: $e');
    }
  }

  // KOMENTAR: Menghapus data siswa berdasarkan NISN
  Future<void> deleteStudent(String nisn) async {
    try {
      await supabase.from('students').delete().eq('nisn', nisn);
    } on PostgrestException catch (e) {
      throw Exception('Gagal menghapus data: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error menghapus data: $e');
    }
  }

  // KOMENTAR: Menguji koneksi ke tabel students
  Future<void> testConnection() async {
    try {
      final response = await supabase.from('students').select('id').limit(1);
      print('Test koneksi berhasil: $response');
    } on PostgrestException catch (e) {
      throw Exception('Gagal menguji koneksi: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Error menguji koneksi: $e');
    }
  }
}