Shindo.tests('Excon request idempotencey') do
  Excon.mock = true

  after do
    # flush any existing stubs after each test
    Excon.stubs.clear
  end

  tests("Non-idempotent call with an erroring socket").raises(Excon::Errors::SocketError) do
    run_count = 0
    Excon.stub({:method => :get}) { |params|
      run_count += 1
      if run_count < 4 # First 3 calls fail.
        raise Excon::Errors::SocketError.new(Exception.new "Mock Error")
      else
        {:body => params[:body], :headers => params[:headers], :status => 200}
      end
    }

    connection = Excon.new('http://127.0.0.1:9292')
    response = connection.request(:method => :get, :path => '/some-path')
  end

  tests("Idempotent request with socket erroring first 3 times").returns(200) do
    run_count = 0
    Excon.stub({:method => :get}) { |params|
      run_count += 1
      if run_count <= 3 # First 3 calls fail.
        raise Excon::Errors::SocketError.new(Exception.new "Mock Error")
      else
        {:body => params[:body], :headers => params[:headers], :status => 200}
      end
    }

    connection = Excon.new('http://127.0.0.1:9292')
    response = connection.request(:method => :get, :idempotent => true, :path => '/some-path')
    response.status
  end

  tests("Idempotent request with socket erroring first 9 times").raises(Excon::Errors::SocketError) do
    run_count = 0
    Excon.stub({:method => :get}) { |params|
      run_count += 1
      if run_count <= 9 # First 5 calls fail.
        raise Excon::Errors::SocketError.new(Exception.new "Mock Error")
      else
        {:body => params[:body], :headers => params[:headers], :status => 200}
      end
    }

    connection = Excon.new('http://127.0.0.1:9292')
    response = connection.request(:method => :get, :idempotent => true, :path => '/some-path')
    response.status
  end

  Excon.mock = false
end
