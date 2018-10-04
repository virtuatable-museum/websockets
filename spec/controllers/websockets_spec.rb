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
        post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test', session_ids: [session.id.to_s]}
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
          post '/messages', {token: 'test_token', app_key: 'other_key', session_ids: [session.id.to_s]}
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
          post '/messages', {token: 'test_token', app_key: 'other_key', session_ids: [session.id.to_s], message: ''}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
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
          post '/messages', {token: 'test_token', app_key: 'other_key', message: 'test'}
        end
        it 'Returns a OK (200) status' do
          expect(last_response.status).to be 400
        end
        it 'Returns the correct body' do
        end
        it 'Returns the correct body' do
          expect(last_response.body).to include_json({
            status: 400,
            field: 'session_ids',
            error: 'required'
          })
        end
      end
    end
  end
end