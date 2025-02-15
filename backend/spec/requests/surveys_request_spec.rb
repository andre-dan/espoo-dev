require 'rails_helper'

RSpec.describe 'SurveysController', type: :request do
  describe '#show' do
    let!(:survey) { create(:survey) }
    let!(:survey_question) { survey.questions.first }
    let!(:question_type) { survey_question.question_type }
    let!(:survey_subject) { survey.survey_subject }
    let!(:option) { create(:option, question: survey_question) }

    before { get api_v1_survey_path(survey), headers: auth_headers }

    it { expect(response).to have_http_status :ok }

    it 'matches surveys attributes' do
      expected_attributes = {
        'id' => anything,
        'name' => survey.name,
        'description' => survey.description,
        'survey_subject_id' => survey_subject.id,
        'questions' => [
          'id' => survey_question.id,
          'name' => survey_question.name,
          'question_type' => {
            'id' => question_type.id,
            'name' => question_type.name
          },
          'options' => [{
            'id' => option.id,
            'name' => option.name,
            'correct' => option.correct
          }]
        ]
      }
      expect(response_body).to match(expected_attributes)
    end
  end

  describe '#index' do
    context 'when can list all ready surveys' do
      before do
        create_list(:ready_survey, 3)
        get api_v1_surveys_path, headers: auth_headers
      end

      it { expect(response).to have_http_status :success }

      it { expect(response_body.count).to eq(3) }
    end

    context "when survey doesn't exist" do
      before do
        get api_v1_surveys_path, headers: auth_headers
      end

      it { expect(response).to have_http_status :success }
      it { expect(response_body).to match([]) }
      it { expect(response_body.count).to eq(0) }
    end

    context 'when list surveys by user id' do
      before do
        user = create(:user)
        create(:ready_survey, name: 'test 1', user_id: user.id)
        create(:ready_survey, name: 'test 2', user_id: user.id)
        another_user = create(:user)
        create(:ready_survey, name: 'test 1', user_id: another_user.id)
        get api_v1_surveys_path(user_id: another_user.id), headers: auth_headers
      end

      it { expect(response).to have_http_status :success }
      it { expect(response_body.count).to eq(1) }
    end

    describe 'when can list surveys by user' do
      let!(:admin) { create(:user) }
      let!(:teacher) { create(:user_teacher) }
      let!(:moderator) { create(:user_moderator) }
      let!(:survey_teacher) { create(:ready_survey, user_id: teacher.id) }

      context 'when the user is an admin' do
        before do
          create(:ready_survey, user_id: admin.id)
          get api_v1_surveys_path, headers: auth_headers
        end

        it { expect(response).to have_http_status :success }
        it { expect(response_body.count).to eq(2) }
      end

      context 'when the user is an teacher' do
        before { get api_v1_surveys_path, headers: auth_headers(user: teacher) }

        it 'survey expect id' do
          resp_id = response_body[0]['id']
          expect(survey_teacher.id).to eq(resp_id)
        end

        it { expect(response).to have_http_status :success }
        it { expect(response_body.count).to eq(1) }
      end

      context 'when user is an moderator' do
        before { get api_v1_surveys_path, headers: auth_headers(user: moderator) }

        it { expect(response).to have_http_status :success }
        it { expect(response_body.count).to eq(0) }
      end
    end
  end
end
