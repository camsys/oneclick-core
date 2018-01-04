class ServiceBookingParamPermitter < HashParamPermitter
  define_hash_structure(
    hash_column: :booking_details, 
    case_column: :booking_api,
    structure: {
      ride_pilot: [ :provider_id ],
      ecolane: [],
      trapeze: [ :provider_id ]
    }
  )
end
