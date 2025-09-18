enum client { Corporate, Private }

enum hire_Type { None, Dropoff, Pick_and_Drop, Full_Day, Half_Day }

enum vat_Type { None, Vatable, Non_Vatable }

enum payment_Methods { Cash, Bank, Paybill }
enum Whos_to_blame {
        
        /// <remarks/>
        _blank_,
        
        /// <remarks/>
        Both,
        
        /// <remarks/>
        Driver,
        
        /// <remarks/>
        Conductor,
        
        /// <remarks/>
        Company,
    }
class Whos_to_blame_for_Deficiet_desc {
  static const Map<Whos_to_blame, String> desc = {
    Whos_to_blame._blank_: 'None',
    Whos_to_blame.Both: 'Both',
    Whos_to_blame.Driver: 'Driver',
    Whos_to_blame.Conductor: 'Conductor',
    Whos_to_blame.Company: 'Company',
  };
}
class hire_type_desc {
  static const Map<hire_Type, String> desc = {
    hire_Type.None: 'None',
    hire_Type.Dropoff: 'Dropoff',
    hire_Type.Pick_and_Drop: 'Pick and Drop',
    hire_Type.Full_Day: 'Full Day',
    hire_Type.Half_Day: 'Half Day',
  };
}
class client_desc {
  static const Map<client, String> desc = {
    client.Corporate: 'Corporate',
    client.Private: 'Private',
  };
}
class vat_type_desc {
  static const Map<vat_Type, String> desc = {
    vat_Type.None: 'None',
    vat_Type.Vatable: 'Vatable',
    vat_Type.Non_Vatable: 'Non Vatable',
  };
}
class payment_methods_desc {
  static const Map<payment_Methods, String> desc = {
    payment_Methods.Cash: 'Cash',
    payment_Methods.Bank: 'Bank',
    payment_Methods.Paybill: 'Paybill',
  };
}