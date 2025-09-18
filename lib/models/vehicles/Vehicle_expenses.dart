class Vehicle_expenses {
  String? Key;
  String? Code;
  String? Vehicle_No;
  DateTime? Date;
 
  String? Expense;
  String? Description;
  String? Created_By;
  double? Amount;

  Vehicle_expenses({
    this.Key,
    this.Code,
    this.Vehicle_No,
    this.Date,
   
    this.Expense,
    this.Description,
    this.Created_By,
    this.Amount,
  });
  factory Vehicle_expenses.fromJson(Map<String, dynamic> json) {
    return Vehicle_expenses(
      Key: json['Key'],
      Code: json['Code'],
      Vehicle_No: json['Vehicle_No'],
      Date: DateTime.parse(json['Date']),
      Expense: json['Expense'],
      Description: json['Description'],
      Created_By: json['Created_By'],
      Amount: json['Amount'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Key': Key,
      'Code': Code,
      'Vehicle_No': Vehicle_No,
      'Date': Date?.toIso8601String(),
      'Expense': Expense,
      'Description': Description,
      'Created_By': Created_By,
      'Amount': Amount,
    };
  }
  @override
  String toString() {
    return 'Vehicle_expenses(Key: $Key, Code: $Code, Vehicle_No: $Vehicle_No, Date: $Date, Expense: $Expense, Description: $Description, Created_By: $Created_By, Amount: $Amount)';
  }
  // You can add methods for JSON serialization/deserialization if needed
}