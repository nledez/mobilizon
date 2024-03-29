# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/formatter.ex

defmodule Mobilizon.Service.Formatter do
  @moduledoc """
  Formats input text to structured data, extracts mentions and hashtags.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.HTML

  @link_regex ~r"((?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~%:/?#[\]@!\$&'\(\)\*\+,;=.]+)|[0-9a-z+\-\.]+:[0-9a-z$-_.+!*'(),]+"ui
  @markdown_characters_regex ~r/(`|\*|_|{|}|[|]|\(|\)|#|\+|-|\.|!)/

  @auto_linker_config hashtag: true,
                      hashtag_handler: &Mobilizon.Service.Formatter.hashtag_handler/4,
                      mention: true,
                      mention_handler: &Mobilizon.Service.Formatter.mention_handler/4

  def escape_mention_handler("@" <> nickname = mention, buffer, _, _) do
    case Mobilizon.Actors.get_actor_by_name(nickname) do
      %Actor{} ->
        # escape markdown characters with `\\`
        # (we don't want something like @user__name to be parsed by markdown)
        String.replace(mention, @markdown_characters_regex, "\\\\\\1")

      _ ->
        buffer
    end
  end

  def mention_handler("@" <> nickname, buffer, _opts, acc) do
    case Actors.get_actor_by_name(nickname) do
      %Actor{id: id, url: url, preferred_username: preferred_username} = actor ->
        link =
          "<span class='h-card'><a data-user='#{id}' class='u-url mention' href='#{url}'>@<span>#{
            preferred_username
          }</span></a></span>"

        {link, %{acc | mentions: MapSet.put(acc.mentions, {"@" <> nickname, actor})}}

      _ ->
        {buffer, acc}
    end
  end

  def hashtag_handler("#" <> tag = tag_text, _buffer, _opts, acc) do
    tag = String.downcase(tag)
    url = "#{MobilizonWeb.Endpoint.url()}/tag/#{tag}"
    link = "<a class='hashtag' data-tag='#{tag}' href='#{url}' rel='tag'>#{tag_text}</a>"

    {link, %{acc | tags: MapSet.put(acc.tags, {tag_text, tag})}}
  end

  @doc """
  Parses a text and replace plain text links with HTML. Returns a tuple with a result text, mentions, and hashtags.

  If the 'safe_mention' option is given, only consecutive mentions at the start the post are actually mentioned.
  """
  @spec linkify(String.t(), keyword()) ::
          {String.t(), [{String.t(), Actor.t()}], [{String.t(), String.t()}]}
  def linkify(text, options \\ []) do
    options = options ++ @auto_linker_config

    acc = %{mentions: MapSet.new(), tags: MapSet.new()}
    {text, %{mentions: mentions, tags: tags}} = AutoLinker.link_map(text, acc, options)

    {text, MapSet.to_list(mentions), MapSet.to_list(tags)}
  end

  @doc """
  Escapes a special characters in mention names.
  """
  def mentions_escape(text, options \\ []) do
    options =
      Keyword.merge(options,
        mention: true,
        url: false,
        mention_handler: &escape_mention_handler/4
      )

    AutoLinker.link(text, options)
  end

  def html_escape({text, mentions, hashtags}, type) do
    {html_escape(text, type), mentions, hashtags}
  end

  def html_escape(text, "text/html") do
    HTML.filter_tags(text)
  end

  def html_escape(text, "text/plain") do
    @link_regex
    |> Regex.split(text, include_captures: true)
    |> Enum.map_every(2, fn chunk ->
      {:safe, part} = Phoenix.HTML.html_escape(chunk)
      part
    end)
    |> Enum.join("")
  end

  def truncate(text, max_length \\ 200, omission \\ "...") do
    # Remove trailing whitespace
    text = Regex.replace(~r/([^ \t\r\n])([ \t]+$)/u, text, "\\g{1}")

    if String.length(text) < max_length do
      text
    else
      length_with_omission = max_length - String.length(omission)
      String.slice(text, 0, length_with_omission) <> omission
    end
  end
end
