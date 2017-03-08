class StateCodeDictionary
  @@STATE_CODE_DICTIONARY = {
    1	=>	{ code: "AL", name: "Alabama"},
    2	=>	{ code: "AK", name: "Alaska"},
    4	=>	{ code: "AZ", name: "Arizona"},
    5	=>	{ code: "AR", name: "Arkansas"},
    6	=>	{ code: "CA", name: "California"},
    8	=>	{ code: "CO", name: "Colorado"},
    9	=>	{ code: "CT", name: "Connecticut"},
    10	=>	{ code: "DE", name: "Delaware"},
    11	=>	{ code: "DC", name: "District of Columbia"},
    12	=>	{ code: "FL", name: "Florida"},
    13	=>	{ code: "GA", name: "Georgia"},
    15	=>	{ code: "HI", name: "Hawaii"},
    16	=>	{ code: "ID", name: "Idaho"},
    17	=>	{ code: "IL", name: "Illinois"},
    18	=>	{ code: "IN", name: "Indiana"},
    19	=>	{ code: "IA", name: "Iowa"},
    20	=>	{ code: "KS", name: "Kansas"},
    21	=>	{ code: "KY", name: "Kentucky"},
    22	=>	{ code: "LA", name: "Louisiana"},
    23	=>	{ code: "ME", name: "Maine"},
    24	=>	{ code: "MD", name: "Maryland"},
    25	=>	{ code: "MA", name: "Massachusetts"},
    26	=>	{ code: "MI", name: "Michigan"},
    27	=>	{ code: "MN", name: "Minnesota"},
    28	=>	{ code: "MS", name: "Mississippi"},
    29	=>	{ code: "MO", name: "Missouri"},
    30	=>	{ code: "MT", name: "Montana"},
    31	=>	{ code: "NE", name: "Nebraska"},
    32	=>	{ code: "NV", name: "Nevada"},
    33	=>	{ code: "NH", name: "New Hampshire"},
    34	=>	{ code: "NJ", name: "New Jersey"},
    35	=>	{ code: "NM", name: "New Mexico"},
    36	=>	{ code: "NY", name: "New York"},
    37	=>	{ code: "NC", name: "North Carolina"},
    38	=>	{ code: "ND", name: "North Dakota"},
    39	=>	{ code: "OH", name: "Ohio"},
    40	=>	{ code: "OK", name: "Oklahoma"},
    41	=>	{ code: "OR", name: "Oregon"},
    42	=>	{ code: "PA", name: "Pennsylvania"},
    44	=>	{ code: "RI", name: "Rhode Island"},
    45	=>	{ code: "SC", name: "South Carolina"},
    46	=>	{ code: "SD", name: "South Dakota"},
    47	=>	{ code: "TN", name: "Tennessee"},
    48	=>	{ code: "TX", name: "Texas"},
    49	=>	{ code: "UT", name: "Utah"},
    50	=>	{ code: "VT", name: "Vermont"},
    51	=>	{ code: "VA", name: "Virginia"},
    53	=>	{ code: "WA", name: "Washington"},
    54	=>	{ code: "WV", name: "West Virginia"},
    55	=>	{ code: "WI", name: "Wisconsin"},
    56	=>	{ code: "WY", name: "Wyoming"},
    60	=>	{ code: "AS", name: "American Samoa"},
    64	=>	{ code: "FM", name: "Federated States of Micronesia"},
    66	=>	{ code: "GU", name: "Guam"},
    68	=>	{ code: "MH", name: "Marshall Islands"},
    69	=>	{ code: "MP", name: "Commonwealth of the Northern Mariana Islands"},
    70	=>	{ code: "PW", name: "Palau"},
    72	=>	{ code: "PR", name: "Puerto Rico"},
    74	=>	{ code: "UM", name: "U.S. Minor Outlying Islands"},
    78	=>	{ code: "VI", name: "U.S. Virgin Islands"}
  }

  def self.code(ansi_code)
    state = @@STATE_CODE_DICTIONARY[ansi_code.to_i]
    state ? state[:code] : nil
  end

  def self.name(ansi_code)
    state = @@STATE_CODE_DICTIONARY[ansi_code.to_i]
    state ? state[:name] : nil
  end
end
