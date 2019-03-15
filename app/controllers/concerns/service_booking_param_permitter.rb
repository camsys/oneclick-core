class ServiceBookingParamPermitter < HashParamPermitter
  define_hash_structure(
    hash_column: :booking_details, 
    case_column: :booking_api,
    structure: {
      ride_pilot: [ :provider_id ],
      ecolane: [ :external_id, :token, :home_counties, :use_ecolane_funding_rules, :ada_funding_sources, :preferred_funding_sources, :preferred_sponsors, :banned_purposes, :banned_users, :trusted_users, :min_days, :max_days, :require_selfservice_validation, :cutoff_time],
      trapeze: [ :trapeze_provider_id ]
    }
  )
end
