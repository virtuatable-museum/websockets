describe Controllers::Websockets do
  before do
    DatabaseCleaner.clean
  end

  let!(:account) { create(:account) }
  let!(:application) { create(:application, creator: account) }
  let!(:gateway) { create(:gateway) }
  let!(:session) { create(:session, account: account) }

  def app
    Controllers::Websockets.new
  end

  describe 'POST /messages' do

    describe 'Nominal case' do
      before do
        post '/websockets/messages', {token: 'test_token', app_key: 'other_key', message: 'test', session_ids: [session.id.to_s], session_id: session.token}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'transmitted'})
      end
    end

    describe '400 errors' do
      describe 'when the message is not given' do
        before do
          post '/websockets/messages', {token: 'test_token', app_key: 'other_key', session_ids: [session.id.to_s], session_id: session.token}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'message',
            error: 'required'
          })
        end
      end
      describe 'when the message is given empty' do
        before do
          post '/websockets/messages', {token: 'test_token', app_key: 'other_key', session_ids: [session.id.to_s], message: '', session_id: session.token}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'message',
            error: 'required'
          })
        end
      end
      describe 'when the session ids are not given' do
        before do
          post '/websockets/messages', {token: 'test_token', app_key: 'other_key', message: 'test', session_id: session.token}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'session_ids',
            error: 'required'
          })
        end
      end
      describe 'when the session_id is not given' do
        before do
          post '/websockets/messages', {token: 'test_token', app_key: 'other_key', message: 'test', session_ids: [session.id.to_s]}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'session_id',
            error: 'required'
          })
        end
      end
    end

    describe '404 errors' do
      describe 'when the session is not found' do
        before do
          post '/websockets/messages', {token: 'test_token', app_key: 'other_key', message: 'test', session_ids: [session.id.to_s], session_id: 'any_unknown_id'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 404
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 404,
            field: 'session_id',
            error: 'unknown'
          })
        end
      end
    end

    it_behaves_like 'a route', 'post', '/websockets/messages'
  end

  describe 'POST /purge' do
    describe 'Nominal case' do
      before do
        post '/websockets/purge', {token: 'test_token', app_key: 'other_key', session_id: session.token}
      end
      it 'Returns a OK (200) status' do
        expect(last_response.status).to be 200
      end
      it 'Returns the correct body' do
        expect(last_response.body).to include_json({message: 'purged'})
      end
    end

    it_behaves_like 'a route', 'post', '/websockets/purge'
  end
end