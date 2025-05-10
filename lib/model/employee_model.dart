class Employee {
  final String uid;
  final String no;
  final String name;
  final String nik;
  final String email;
  final String gender;
  final String dob;
  final String pob;
  final String position;
  final String religion;
  final String address;
  final String employeeStatus;
  final String joinDate;
  final String phone;

  Employee({
    required this.uid,
    required this.no,
    required this.name,
    required this.nik,
    required this.email,
    required this.gender,
    required this.dob,
    required this.pob,
    required this.position,
    required this.religion,
    required this.address,
    required this.employeeStatus,
    required this.joinDate,
    required this.phone,
  });

  Employee copyWith({
    String? no,
    String? name,
    String? nik,
    String? email,
    String? gender,
    String? dob,
    String? pob,
    String? position,
    String? religion,
    String? address,
    String? employeeStatus,
    String? joinDate,
    String? phone,
  }) {
    return Employee(
      uid: uid,
      no: no ?? this.no,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      position: position ?? this.position,
      religion: religion ?? this.religion,
      address: address ?? this.address,
      employeeStatus: employeeStatus ?? this.employeeStatus,
      joinDate: joinDate ?? this.joinDate,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'no': no,
      'name': name,
      'nik': nik,
      'email': email,
      'gender': gender,
      'dob': dob,
      'pob': pob,
      'position': position,
      'religion': religion,
      'address': address,
      'employeeStatus': employeeStatus,
      'joinDate': joinDate,
      'phone': phone,
    };
  }
}
