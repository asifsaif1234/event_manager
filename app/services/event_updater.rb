class EventUpdater
  def self.changed?(event, api_event)
    event.title != api_event["title"] ||
    event.description != api_event["description"] ||
    event.start_date != api_event["startdate"] ||
    event.end_date != api_event["enddate"] ||
    event.image_link != api_event["image_link"] ||
    event.url != api_event["url"] ||
    event.state != api_event["state"] ||
    event.availability != api_event["availability"] ||
    event.price_amount_in_cents != api_event.dig("minimum_price", "amount_in_cents") ||
    event.price_currency != api_event.dig("minimum_price", "currency") ||
    event.organiser_data != api_event["organiser"] ||
    event.location_data != api_event["location"] ||
    event.categorization_data != api_event["categorization"] ||
    event.organization_data != api_event["organization"]
  end

  def self.assign_attributes(event, api_event)
    event.assign_attributes(
      event_id: api_event["id"],
      object_type: api_event["object"],
      kind: api_event["kind"],
      state: api_event["state"],
      title: api_event["title"],
      description: api_event["description"],
      url: api_event["url"],
      branded_url: api_event["branded_url"],
      image_link: api_event["image_link"],
      start_date: api_event["startdate"],
      end_date: api_event["enddate"],
      availability: api_event["availability"],
      price_amount_in_cents: api_event.dig("minimum_price", "amount_in_cents"),
      price_currency: api_event.dig("minimum_price", "currency"),
      organiser_data: api_event["organiser"] || {},
      location_data: api_event["location"] || {},
      categorization_data: api_event["categorization"] || {},
      organization_data: api_event["organization"] || {}
    )
  end
end