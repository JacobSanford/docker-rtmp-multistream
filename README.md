# unb-libraries/docker-nginx  [![](https://github.com/unb-libraries/docker-nginx/workflows/build-test-deploy/badge.svg?branch=1.x)](https://github.com/unb-libraries/docker-nginx/actions?query=workflow%3Abuild-test-deploy) [![GitHub license](https://img.shields.io/github/license/unb-libraries/docker-nginx)](https://github.com/unb-libraries/lib.unb.ca/blob/prod/LICENSE) ![GitHub repo size](https://img.shields.io/github/repo-size/unb-libraries/docker-nginx?label=lean%20repo%20size)
A lightweight extensible nginx docker image, suitable for development or production deployments.

## Usage
```
docker run \
       --rm \
       --name nginx \
       -v /local/dir:/app/html \
       -p 80:80 \
       ghcr.io/unb-libraries/nginx:1.x
```

## Author / Contributors
This application was created at [![UNB Libraries](https://github.com/unb-libraries/assets/raw/master/unblibbadge.png "UNB Libraries")](https://lib.unb.ca) by the following humans:

<a href="https://github.com/JacobSanford"><img src="https://avatars.githubusercontent.com/u/244894?v=3" title="Jacob Sanford" width="128" height="128"></a>

## License
- As part of our 'open' ethos, UNB Libraries licenses its applications and workflows to be freely available to all whenever possible.
- Consequently, the contents of this repository [unb-libraries/docker-nginx] are licensed under the [MIT License](http://opensource.org/licenses/mit-license.html). This license explicitly excludes:
  - Any website content, which remains the exclusive property of its author(s).
  - The UNB logo and any of the associated suite of visual identity assets, which remains the exclusive property of the University of New Brunswick.
