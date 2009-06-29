module S3
  class Service
    extend Roxy::Moxie

    attr_reader :access_key_id, :secret_access_key

    def initialize(options)
      @access_key_id = options[:access_key_id] or raise ArgumentError.new("no access key id given")
      @secret_access_key = options[:secret_access_key] or raise ArgumentError.new("no secret access key given")
      @use_ssl = options[:use_ssl]
      @timeout = options[:timeout]
    end

    def buckets
      response = connection.request(:get, :path => "/")
      parse_buckets(response.body)
    end

    proxy :buckets do
      def build(name)
        Bucket.new(proxy_owner, name)
      end

      def find(name)
        bucket = Bucket.new(proxy_owner, name)
        bucket.exists?
        bucket
      end
    end

    protected

    def connection
      unless defined?(@connection)
        @connection = Connection.new
        @connection.access_key_id = @access_key_id
        @connection.secret_access_key = @secret_access_key
        @connection.use_ssl = @use_ssl
        @connection.timeout = @timeout
      end
      @connection
    end

    private

    def parse_buckets(xml_body)
      xml = XmlSimple.xml_in(xml_body)
      buckets_names = xml["Buckets"].first["Bucket"].map { |bucket| bucket["Name"].first }
      buckets_names.map do |bucket_name|
        Bucket.new(self, bucket_name)
      end
    end
  end
end