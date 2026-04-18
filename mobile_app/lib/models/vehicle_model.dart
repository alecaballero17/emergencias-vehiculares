class Vehicle {
  final int id;
  final String brand;
  final String model;
  final String plateNumber;
  final String color;
  final int year;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.plateNumber,
    required this.color,
    required this.year,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      brand: json['brand'],
      model: json['model'],
      plateNumber: json['license_plate'],
      color: json['color'],
      year: json['year'],
    );
  }

  String get displayName => '$brand $model ($plateNumber)';
}
