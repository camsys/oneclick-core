class ServiceBookingParamPermitter < HashParamPermitter
  define_hash_structure(
    hash_column: :booking_details, 
    case_column: :booking_api,
    structure: {
      ride_pilot: [ :provider_id ],
      ecolane: [ :external_id, :token, :home_counties, :ada_funding_sources ],
      trapeze: [ :trapeze_provider_id ]
    }
  )
end
