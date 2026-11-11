import { useRef, useState } from 'react';
import { api } from '../api.js';
import { handleFieldBlur, handleFieldInput, validateFormControls } from '../formValidation.js';
import { EyeIcon, EyeOffIcon, HeartPulseIcon, LockIcon } from './Icons.jsx';

export function LoginView({ sessionInfo, onSignedIn }) {
  const formRef = useRef(null);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  async function handleSubmit(event) {
    event.preventDefault();
    setErrorMessage('');
    const form = formRef.current;
    if (!validateFormControls(form)) {
      form?.reportValidity();
      return;
    }

    setSubmitting(true);
    try {
      const nextSession = await api.login({
        username,
        password,
      });
      onSignedIn(nextSession);
    } catch (err) {
      setErrorMessage(err.message || 'Could not sign in. Please check your login details.');
    } finally {
      setSubmitting(false);
    }
  }

  function fillDefaultCredentials() {
    if (!sessionInfo?.default_username || !sessionInfo?.default_password) return;
    setUsername(sessionInfo.default_username);
    setPassword(sessionInfo.default_password);
    setErrorMessage('');
  }

  return (
    <div className="login-shell">
      <div className="login-card card card--padded">
        <div className="login-card__brand">
          <span className="brand__badge" aria-hidden="true">
            <HeartPulseIcon className="brand__icon" />
          </span>
          <div>
            <h1 className="login-card__title">Sign In to My Health Tracker</h1>
            <p className="login-card__subtitle">
              Keep your blood glucose, blood pressure, and heart rate readings private on this
              device.
            </p>
          </div>
        </div>

        <form
          ref={formRef}
          method="POST"
          action="/api/auth/login"
          onSubmit={handleSubmit}
          className="health-form"
        >
          <div className="form-group">
            <label htmlFor="username">
              Username <span aria-hidden="true" className="req-star">*</span>
            </label>
            <input
              id="username"
              name="username"
              type="text"
              autoComplete="username"
              autoCorrect="off"
              autoCapitalize="off"
              spellCheck={false}
              enterKeyHint="next"
              required
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              onBlur={handleFieldBlur}
              onInput={handleFieldInput}
              placeholder="Enter your username"
            />
            <span className="error-msg">
              <span aria-hidden="true">!</span> Please enter your username.
            </span>
          </div>

          <div className="form-group">
            <label htmlFor="current-password">
              Password <span aria-hidden="true" className="req-star">*</span>
            </label>
            <div className="password-field">
              <input
                id="current-password"
                name="current-password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                enterKeyHint="done"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onBlur={handleFieldBlur}
                onInput={handleFieldInput}
                placeholder="Enter your password"
              />
              <button
                type="button"
                className="btn btn--ghost btn--compact password-toggle"
                aria-pressed={showPassword}
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                aria-describedby="login-toggle-warning"
                onClick={() => setShowPassword((prev) => !prev)}
              >
                {showPassword ? <EyeOffIcon className="btn__icon" /> : <EyeIcon className="btn__icon" />}
                <span>{showPassword ? 'Hide' : 'Show'}</span>
              </button>
            </div>
            <span className="error-msg">
              <span aria-hidden="true">!</span> Please enter your password.
            </span>
            <span id="login-toggle-warning" className="visually-hidden">
              Showing your password displays the characters on screen.
            </span>
          </div>

          {errorMessage && (
            <div role="alert" className="alert-banner alert-banner--red">
              <span>{errorMessage}</span>
            </div>
          )}

          <button
            type="submit"
            className="btn btn--primary btn--large-full"
            disabled={submitting}
          >
            <LockIcon className="btn__icon" />
            <span>{submitting ? 'Signing In...' : 'Sign In'}</span>
          </button>
        </form>

        {sessionInfo?.show_default_hint ? (
          <section className="default-creds-box" aria-label="Default login details">
            <div className="default-creds-box__text">
              <strong>Default Login Details</strong>
              <p>
                Username: <code>{sessionInfo.default_username}</code> · Password:{' '}
                <code>{sessionInfo.default_password}</code>
              </p>
              <span className="field-hint">
                You can change these login details anytime after signing in.
              </span>
            </div>
            <button
              type="button"
              className="btn btn--secondary btn--compact"
              onClick={fillDefaultCredentials}
            >
              Use Default Details
            </button>
          </section>
        ) : (
          <p className="field-hint login-privacy-note">
            Your custom login details are active. Update your username or password anytime from
            Login Details after signing in.
          </p>
        )}
      </div>
    </div>
  );
}

