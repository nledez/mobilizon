defmodule MobilizonWeb.Cache.ActivityPub do
  @moduledoc """
  The ActivityPub related functions.
  """

  alias Mobilizon.{Actors, Events, Service}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Comment, Event}
  alias Service.ActivityPub

  @cache :activity_pub

  @doc """
  Gets a local actor by username.
  """
  @spec get_local_actor_by_name(String.t()) ::
          {:commit, Actor.t()} | {:ignore, nil}
  def get_local_actor_by_name(name) do
    Cachex.fetch(@cache, "actor_" <> name, fn "actor_" <> name ->
      case Actors.get_local_actor_by_name(name) do
        %Actor{} = actor ->
          {:commit, actor}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a public event by its UUID, with all associations loaded.
  """
  @spec get_public_event_by_uuid_with_preload(String.t()) ::
          {:commit, Event.t()} | {:ignore, nil}
  def get_public_event_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "event_" <> uuid, fn "event_" <> uuid ->
      case Events.get_public_event_by_uuid_with_preload(uuid) do
        %Event{} = event ->
          {:commit, event}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a comment by its UUID, with all associations loaded.
  """
  @spec get_comment_by_uuid_with_preload(String.t()) ::
          {:commit, Comment.t()} | {:ignore, nil}
  def get_comment_by_uuid_with_preload(uuid) do
    Cachex.fetch(@cache, "comment_" <> uuid, fn "comment_" <> uuid ->
      case Events.get_comment_from_uuid_with_preload(uuid) do
        %Comment{} = comment ->
          {:commit, comment}

        nil ->
          {:ignore, nil}
      end
    end)
  end

  @doc """
  Gets a relay.
  """
  @spec get_relay :: {:commit, Actor.t()} | {:ignore, nil}
  def get_relay do
    Cachex.fetch(@cache, "relay_actor", &ActivityPub.Relay.get_actor/0)
  end
end
