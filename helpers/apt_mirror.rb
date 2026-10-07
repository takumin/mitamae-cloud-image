# frozen_string_literal: true

#
# Apt Mirror
#

# Pick the build-time mirror (APT_REPO_URL_*) for an apt_repository uri when
# it is set, and remember its default uri so that the cleanup recipe can
# restore it, since the mirrors are only reachable from the build host
unless Object.const_defined?(:AptMirror)
  module ::AptMirror
    DEFAULT_URIS = {}

    def self.uri(default_uri, mirror_uri)
      return default_uri unless mirror_uri.is_a?(String) and mirror_uri.match?(/^(?:file|https?):\/\//)

      DEFAULT_URIS[mirror_uri] = default_uri
      mirror_uri
    end

    def self.default_uri(uri)
      DEFAULT_URIS[uri]
    end
  end
end
