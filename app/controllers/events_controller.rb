class EventsController < ApplicationController
  def index
    @events = Event.published.upcoming.available
    # Will implement pagination later
    # @events = @events.page(params[:page]).per(20)

    @last_ingestion = Rails.cache.read("last_event_ingestion")
  end

  def ingest
    EventIngestionJob.perform_later(limit: 10)

    flash[:notice] = "Event ingestion started in background. It may take a few moments."
    redirect_to events_path
  end

  def ingest_all
    EventIngestionJob.perform_later

    flash[:notice] = "Full event ingestion started in background. This may take several minutes."
    redirect_to events_path
  end

  def sync_status
    status = Rails.cache.read("last_event_ingestion")

    if status
      render json: {
        success: true,
        last_run: status[:timestamp],
        results: status[:result]
      }
    else
      render json: { success: false, message: "No ingestion has been run yet" }
    end
  end
end
