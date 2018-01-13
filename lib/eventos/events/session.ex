defmodule Eventos.Events.Session do
  use Ecto.Schema
  import Ecto.Changeset
  alias Eventos.Events.{Session, Event, Track}


  schema "sessions" do
    field :audios_urls, :string
    field :language, :string
    field :long_abstract, :string
    field :short_abstract, :string
    field :slides_url, :string
    field :subtitle, :string
    field :title, :string
    field :videos_urls, :string
    field :begins_on, Timex.Ecto.DateTimeWithTimezone
    field :ends_on, Timex.Ecto.DateTimeWithTimezone
    belongs_to :event, Event
    belongs_to :track, Track

    timestamps()
  end

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:title, :subtitle, :short_abstract, :long_abstract, :language, :slides_url, :videos_urls, :audios_urls, :event_id, :track_id])
    |> validate_required([:title, :subtitle, :short_abstract, :long_abstract, :language, :slides_url, :videos_urls, :audios_urls])
  end
end